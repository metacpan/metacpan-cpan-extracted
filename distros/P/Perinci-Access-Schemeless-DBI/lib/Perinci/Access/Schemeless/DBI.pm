package Perinci::Access::Schemeless::DBI;

our $DATE = '2016-03-16'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

use JSON::MaybeXS;
my $json = JSON::MaybeXS->new->allow_nonref;

use parent qw(Perinci::Access::Schemeless);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # check required attributes
    my $dbh = $self->{dbh};
    die "Please specify required attribute 'dbh'" unless $dbh;

    # if this looks like a table created by App::UpdateRinciMetadataDb, check
    # its version
    {
        my @tt = $dbh->tables(undef, undef);
        last unless grep {$_ eq 'meta' || $_ eq '"meta"' || $_ eq '"main"."meta"'} @tt;

        my ($sch_ver) = $dbh->selectrow_array(
            "SELECT value FROM meta WHERE name='schema_version'");
        if (!$sch_ver || $sch_ver ne '2') {
            die "Database schema not supported, only version 2 is supported";
        }
    }

    $self->{fallback_on_completion} //= 0;

    $self;
}

sub get_meta {
    my ($self, $req) = @_;

    my $leaf = $req->{-uri_leaf};

    if (length $leaf) {
        my ($meta) = $self->{dbh}->selectrow_array(
            "SELECT metadata FROM function WHERE package=? AND name=?", {},
            $req->{-perl_package}, $leaf);
        if ($meta) {
            $req->{-meta} = $json->decode($meta);
        } else {
            return [404, "No metadata found in database for package ".
                        "'$req->{-perl_package}' and function '$leaf'"];
        }
    } else {
        # XXP check in database, if exists return if not return {v=>1.1}
        my ($meta) = $self->{dbh}->selectrow_array(
            "SELECT metadata FROM package WHERE name=?", {},
            $req->{-perl_package});
        if ($meta) {
            $req->{-meta} = $json->decode($meta);
        } else {
            $req->{-meta} = {v=>1.1}; # empty metadata for /
        }
    }
    return;
}

sub action_list {
    my ($self, $req) = @_;
    my $detail = $req->{detail};
    my $f_type = $req->{type} || "";

    my @res;

    # XXX duplicated code with parent class
    my $filter_path = sub {
        my $path = shift;
        if (defined($self->{allow_paths}) &&
                !Perinci::Access::Schemeless::__match_paths2($path, $self->{allow_paths})) {
            return 0;
        }
        if (defined($self->{deny_paths}) &&
                Perinci::Access::Schemeless::__match_paths2($path, $self->{deny_paths})) {
            return 0;
        }
        1;
    };

    my $sth;
    my %mem;

    my $pkg = $req->{-perl_package};

    # get subpackages
    unless ($f_type && $f_type ne 'package') {
        if (length $pkg) {
            $sth = $self->{dbh}->prepare(
                "SELECT name FROM package WHERE name LIKE ? ORDER BY name");
            $sth->execute("$pkg\::%");
        } else {
            $sth = $self->{dbh}->prepare(
                "SELECT name FROM package ORDER BY name");
            $sth->execute;
        }
        while (my $r = $sth->fetchrow_hashref) {
            # strip pkg from name
            my $m = substr($r->{name}, length($pkg));

            # strip :: prefix
            $m =~ s/\A:://;

            # only take the first sublevel, e.g. if user requests 'foo::bar' and
            # db lists 'foo::bar::baz::quux', then we only want 'baz'.
            ($m) = $m =~ /(\w+)/;
            $m .= "/";

            next if $mem{$m}++;

            if ($detail) {
                push @res, {uri=>$m, type=>"package"};
            } else {
                push @res, $m;
            }
        }
    }

    # get all entities from this package. XXX currently only functions
    my $dir = $req->{-uri_dir};
    $sth = $self->{dbh}->prepare(
        "SELECT name FROM function WHERE package=? ORDER BY name");
    $sth->execute($req->{-perl_package});
    while (my $r = $sth->fetchrow_hashref) {
        my $e = $r->{name};
        my $path = "$dir/$e";
        next unless $filter_path->($path);
        my $t = $e =~ /^[%\@\$]/ ? 'variable' : 'function';
        next if $f_type && $f_type ne $t;
        if ($detail) {
            push @res, {
                #v=>1.1,
                uri=>$e, type=>$t,
            };
        } else {
            push @res, $e;
        }
    }

    [200, "OK (list action)", \@res];
}

sub action_complete_arg_val {
    my ($self, $req) = @_;

    goto FALLBACK unless $self->{fallback_on_completion};

    my $arg = $req->{arg} or return err(400, "Please specify arg");

    $self->get_meta($req);
    my $c = $req->{-meta}{args}{$arg}{completion};
    goto FALLBACK unless defined($c) && ref($c) ne 'CODE';

    # get meta from parent's get_meta
    no warnings 'redefine';
    local *get_meta = \&Perinci::Access::Schemeless::get_meta;
    delete $req->{-meta};

  FALLBACK:
    $self->SUPER::action_complete_arg_val($req);
}

sub action_complete_arg_elem {
    my ($self, $req) = @_;

    goto FALLBACK unless $self->{fallback_on_completion};

    my $arg = $req->{arg} or return err(400, "Please specify arg");

    my $c = $req->{-meta}{$arg}{element_completion};
    goto FALLBACK unless defined($c) && ref($c) ne 'CODE';

    # get meta from parent's get_meta
    local *get_meta = \&Perinci::Access::Schemeless::get_meta;
    delete $req->{-meta};

  FALLBACK:
    $self->SUPER::action_complete_arg_elem($req);
}

1;
# ABSTRACT: Subclass of Perinci::Access::Schemeless which gets lists of entities (and metadata) from DBI database

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Schemeless::DBI - Subclass of Perinci::Access::Schemeless which gets lists of entities (and metadata) from DBI database

=head1 VERSION

This document describes version 0.08 of Perinci::Access::Schemeless::DBI (from Perl distribution Perinci-Access-Schemeless-DBI), released on 2016-03-16.

=head1 SYNOPSIS

 use DBI;
 use Perinci::Access::Schemeless::DBI;

 my $dbh = DBI->connect(...);
 my $pa = Perinci::Access::Schemeless::DBI->new(dbh => $dbh);

 my $res;

 # will retrieve list of code entities from database
 $res = $pa->request(list => "/Foo/");

 # will also get metadata from database
 $res = $pa->request(meta => "/Foo/Bar/func1");

 # the rest are the same like Perinci::Access::Schemeless
 $res = $pa->request(actions => "/Foo/");

=head1 DESCRIPTION

This subclass of Perinci::Access::Schemeless gets lists of code entities
(currently only packages and functions) from a DBI database (instead of from
listing Perl packages on the filesystem). It can also retrieve L<Rinci> metadata
from said database (instead of from C<%SPEC> package variables).

Currently, you must have a table containing list of packages named C<package>
with columns C<name> (package name), C<metadata> (Rinci metadata, encoded in
JSON); and a table containing list of functions named C<function> with columns
C<package> (package name), C<name> (function name), and C<metadata> (normalized
Rinci metadata, encoded in JSON). Table and column names will be configurable in
the future. An example of the table's contents:

 name      metadata
 ----      ---------
 Foo::Bar  (null)
 Foo::Baz  {"v":"1.1"}

 package   name         metadata
 ------    ----         --------
 Foo::Bar  func1        {"v":"1.1","summary":"function 1","args":{}}
 Foo::Bar  func2        {"v":"1.1","summary":"function 2","args":{}}
 Foo::Baz  func3        {"v":"1.1","summary":"function 3","args":{"a":{"schema":["int",{},{}]}}}

=for Pod::Coverage ^(.+)$

=head1 HOW IT WORKS

The subclass overrides C<get_meta()> and C<action_list()>. Thus, this modifies
behaviors of the following Riap actions: C<list>, C<meta>, C<child_metas>.

=head1 new(%args) => OBJ

Aside from its parent class, this class recognizes these attributes:

=over

=item * dbh => OBJ (required)

DBI database handle.

=item * fallback_on_completion => BOOL (default: 0)

If set to true, then for C<complete_arg_val> and C<complete_arg_elem>, if
metadata has a non-coderef C<completion> or C<element_completion> in its
argument spec, then will fallback to parent class L<Perinci::Access::Schemeless>
for metadata.

=back

=head1 METHODS

=head1 FAQ

=head2 Rationale for this module?

If you have a large number of packages and functions, you might want to avoid
reading Perl modules on the filesystem.

=head2 I have completion routine for my argument, completion no longer works?

For example, suppose your function metadata is something like this:

 {
     v => 1.1,
     summary => 'Delete account',
     args => {
         name => {
             summary => 'Account name',
             completion => sub {
                 my %args = @_;
                 my $word = $args{word};
                 search_accounts(prefix => $word);
             },
         },
     },
 }

When this is stored in the database, most serialization format (JSON included)
doesn't save the code in C<completion>. If you use L<Data::Clean::JSON>, by
default the coderef will be replaced with plain string C<CODE>. This prevents
completion to work e.g. if you request with this Riap request:

 {action=>'complete_arg_val', uri=>..., arg=>'name'}

One solution is to fallback to its parent class L<Perinci::Access::Schemeless>
(which reads metadata from Perl source files) for meta request when doing
completion. To do this, you can set the attribute C<fallback_on_completion>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Schemeless-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-Schemeless-DBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Schemeless-DBI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Riap>, L<Rinci>

L<App::UpdateRinciMetadataDb>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
