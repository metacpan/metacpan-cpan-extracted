package Parse::CPAN::Cached;

use Moose;
use Carp qw<carp>;
use CPAN::Mini;
use Path::Class;
use App::Cache;
use Parse::CPAN::Authors;
use Parse::CPAN::Packages;
use Parse::CPAN::Whois;

our $VERSION = '0.02';

has 'cpan_mini_config' => (
    is            => 'ro',
    isa           => 'HashRef',
    default       => sub { return { CPAN::Mini->read_config } },
);
has 'cache' => (
    is            => 'ro',
    isa           => 'Object',
    default       => sub { return App::Cache->new() },
    documentation => 'optional App::Cache compatible object',
);
has 'cache_dir' => (
    is            => 'ro',
    isa           => 'Str',
    lazy_build    => 1,                  # we're using other constructor params
    init_arg      => undef,              # private. can't be set via constructor
);
has 'parsers' => (
    is            => 'rw',
    isa           => 'HashRef',
    default       => sub { return {
        packages => {
            file   => '02packages.details.txt.gz',
            subdir => 'modules',
            parser => 'Parse::CPAN::Packages',
        },
        authors => {
            file   => '01mailrc.txt.gz',
            subdir => 'authors',
            parser => 'Parse::CPAN::Authors',
        },
        whois   => {
            file   => '00whois.xml',
            subdir => 'authors',
            parser => 'Parse::CPAN::Whois',
        },
    } },
);
has 'info' => (
    is            => 'rw',
    isa           => 'CodeRef',
    default       => sub { sub { } },
    documentation => q{coderef called with single string param of debug info},
);

sub _build_cache_dir {
    my ($self) = @_;
    my $dir = $self->cpan_mini_config->{local};
    die 'Have you loaded minicpan? No local dir in config' if !defined $dir;
    my @a = glob $dir;
    die "local dir in cpan_mini_config '$dir' not valid"              if !@a;
    die "local dir in cpan_mini_config '$dir' matches multiple files" if @a > 1;
    return $a[0];
}

sub parse_cpan {
    my ($self, $type, $upgrade) = @_;

    die 'No type' if !defined $type;
    die "Unknown cpan type '$type'\n"
        if !$self->parsers->{$type};

    # Silently upgrade authors to whois iff available
    if ($type eq 'authors') {
        my $whois = $self->parse_cpan(whois => 1);
        return $whois if $whois;
    }

    my $filename = file(
        $self->cache_dir,
        $self->parsers->{$type}{subdir},
        $self->parsers->{$type}{file}
    )->stringify;

    return
        if $type eq 'whois'
        && !-f $filename
        && $upgrade;

    die "$filename not found"
        if !-f $filename;

    my $real_type = $type eq 'whois' && $upgrade ? 'authors' : $type;
    return $self->cache->get_code(
        $filename,
        sub {
            $self->info->("Caching '$filename' for $real_type");
            $self->parsers->{$type}{parser}->new($filename);
        }
    );
}

1;

__END__

=head1 NAME

Parse::CPAN::Cached - Parse CPAN meta files & cache the results

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Ensure you already have a L<CPAN::Mini> mirror setup, then:

    use Parse::CPAN::Cached;
    my $parsers       = Parse::CPAN::Cached->new();

    # $authors is a Parse::CPAN::Authors (or Parse::CPAN::Whois) object
    my $authors       = $parsers->parse_cpan('authors');

    # $distributions is a Parse::CPAN::Packages object
    my $distributions = $parsers->parse_cpan('packages');

=head1 DESCRIPTION

Parsing the CPAN meta data files can take a few seconds if you do it normally:

  my $p = Parse::CPAN::Packages->new($filename);

this wraps the parsing/loading with App::Cache which in turn stores the initial
parse in a storable file.

Provided the cache hasn't expired, subsequent calls are loaded from this
storable file rather than being re-parsed from the original cpan metadata file.
If the cache has expired, we re-parse the source.

This is probably redundant unless you are repeatadly opening these files (in
different processes perhaps).

Note: 02packages.details.txt.gz (circa 2009-03) is ~730KB on disk but 13MB as a
(App::Cached generated) Storable file.  We're trading disk & memory for speed.

=head1 CONSTRUCTOR METHODS

All are optional.

=head2 cpan_mini_config

Defaults to the result of calling CPAN::Mini->read_config.  We only use the
'local' value returned, so you could say:

    my $parsers = Parse::CPAN::Cached->new(
        cpan_mini_config => { local => '/path/to/mini_cpan/' }
    );

=head2 cache

Defaults to App::Cache->new().  If you want to change any of the defaults in
App::Cache, construct your own App::Cache first and pass it in.

=head2 info

A coderef that is called to emit some information about what is going on.  By
default, we're silent under normal operation but if you want a little more
detail about what is happening pass in a coderef that accepts a single string
parameter.

    my $parsers = Parse::CPAN::Cached->new(
        info => sub { warn @_, "\n" }
    );

Currently the only time this is used is when we're about to parse one of the
cpan meta data files form scratch, rather than loading in the data via the
cache.

=head1 METHODS

There is only one.

=head2 parse_cpan

Give it the key, get back the appropriate Parse::CPAN::Foo object.

    my $parsers = Parse::CPAN::Cached->new();
    my $result  = $parsers->parse_cpan($key);

Where $key is one of:

=head3 packages

Returns a Parse::CPAN::Packages object.

=head3 authors

Returns either a Parse::CPAN::Authors object or a (api compatible)
Parse::CPAN::Whois object if the 00whois.xml file exists.

=head3 whois

Returns a Parse::CPAN::Whois object.

=head1 AUTHOR

Sysmon, C<< <sysmonblog at googlemail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-cpan-cached at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-CPAN-Cached>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::CPAN::Cached

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-CPAN-Cached>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-CPAN-Cached>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-CPAN-Cached>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-CPAN-Cached>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Sysmon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
