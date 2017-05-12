package Perinci::Access::Schemeless::Hash;

our $DATE = '2016-08-18'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Perinci::Access::Schemeless);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    # check required attributes
    my $hash = $self->{hash};
    die "Please specify required attribute 'hash'" unless ref($hash) eq 'HASH';

    # check structure of hash
    my @keys = sort keys %$hash;
    for my $k (@keys) {
        my $v = $hash->{$k};
        die "Attribute 'hash': key (uri) '$k': value must be array [META, ...]"
            unless ref $v eq 'ARRAY' && ref $v->[0] eq 'HASH';
    }

    $self->{fallback_on_completion} //= 0;

    # cache for performance
    $self->{_hash_keys} = \@keys;

    $self;
}

sub get_meta {
    my ($self, $req) = @_;

    my $uri = $req->{uri};

    # exact match
    if (exists $self->{hash}{$uri}) {
        $req->{-meta} = $self->{hash}{$uri}[0];
        return 0;
    }

    # a "folder" /foo/ is assumed to exists if a uri /foo/SOMETHING exists
    if ($uri =~ m!/\z!) {
        for my $k (@{ $self->{_hash_keys} }) {
            if (index($k, $uri, 0) == 0) {
                $req->{-meta} = {v => 1.1};
                return 0;
            }
        }
    }

    [404, "No metadata found at specified URI"];
}

sub action_list {
    my ($self, $req) = @_;
    my $detail = $req->{detail};
    my $f_type = $req->{type} || "";

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

    my $uri = $req->{uri};

    my $res = $self->get_meta($req);
    return $res if $res;

    my @res;
    my %mem;
    for my $k (sort keys %{ $self->{hash} }) {
        my $v = $self->{hash}{$k};
        next unless $k =~ m!\A\Q$uri\E(\w+/?)!;
        my $child = $1;
        next unless $filter_path->($k);
        next if $mem{$child}++;
        if ($detail) {
            push @res, {
                uri  => $child,
                type => ($child =~ m!/\z! ? "package" : "function"),
            };
        } else {
            push @res, $child;
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
# ABSTRACT: Subclass of Perinci::Access::Schemeless which gets lists of entities (and metadata) from hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Schemeless::Hash - Subclass of Perinci::Access::Schemeless which gets lists of entities (and metadata) from hash

=head1 VERSION

This document describes version 0.003 of Perinci::Access::Schemeless::Hash (from Perl distribution Perinci-Access-Schemeless-Hash), released on 2016-08-18.

=head1 SYNOPSIS

 use Perinci::Access::Schemeless::Hash;

 my $pa = Perinci::Access::Schemeless::DBI->new(hash => {
     '/'              => [{v=>1.1}],
     '/Foo/'          => [{v=>1.1}],
     '/Foo/Bar/'      => [{v=>1.1}],
     '/Foo/Bar/func1' => [{v=>1.1, summary=>"function 1", args=>{}}],
     '/Foo/Bar/func2' => [{v=>1.1, summary=>"function 2", args=>{}}],
     '/Foo/Bar/Sub/'  => [{v=>1.1}],
     '/Foo/Baz/'      => [{v=>1.1}],
     '/Foo/Baz/func3' => [{v=>1.1, summary=>"function 3", args=>{a=>{schema=>["int",{},{}]}}}],
 });

 my $res;

 # will retrieve list of code entities from hash
 $res = $pa->request(list => "/Foo/");

 # will also get metadata from database
 $res = $pa->request(meta => "/Foo/Bar/func1");

 # the rest are the same like Perinci::Access::Schemeless
 $res = $pa->request(actions => "/Foo/");

=head1 DESCRIPTION

This subclass of L<Perinci::Access::Schemeless> gets lists of code entities
(currently only packages and functions) from a hash instead of from listing Perl
packages on the filesystem. It can also retrieve L<Rinci> metadata from said
hash instead of from C<%SPEC> package variables.

As shown in the example in Synopsis, the hash's keys must be absolute URI path.
For package entities, the path must end with slash. The hash's values are
arrayref where the first element of the array is the Rinci metadata.

=for Pod::Coverage ^(.+)$

=head1 HOW IT WORKS

The subclass overrides C<get_meta()> and C<action_list()>. Thus, this modifies
behaviors of the following Riap actions: C<list>, C<meta>, C<child_metas>.

=head1 new(%args) => OBJ

Aside from its parent class, this class recognizes these attributes:

=over

=item * hash => hash (required)

The hash which contains the URI paths and metadata.

=item * fallback_on_completion => BOOL (default: 0)

If set to true, then for C<complete_arg_val> and C<complete_arg_elem>, if
metadata has a non-coderef C<completion> or C<element_completion> in its
argument spec, then will fallback to parent class L<Perinci::Access::Schemeless>
for metadata.

=back

=head1 METHODS

=head1 FAQ

=head2 Rationale for this module?

Security: you can preload the hash with only the URLs you want to make
available.

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

When this is stored in a file, most serialization formats (JSON included) don't
save the code in C<completion>. If you use L<Data::Clean::JSON>, by default the
coderef will be replaced with plain string C<CODE>. This prevents completion to
work e.g. if you request with this Riap request:

 {action=>'complete_arg_val', uri=>..., arg=>'name'}

One solution is to fallback to its parent class L<Perinci::Access::Schemeless>
(which reads metadata from Perl source files) for meta request when doing
completion. To do this, you can set the attribute C<fallback_on_completion>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Schemeless-Hash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-Schemeless-Hash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Schemeless-Hash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Riap>, L<Rinci>

L<Perinci::Access::Schemeless::DBI>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
