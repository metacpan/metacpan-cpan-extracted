package Silki::Help::File;
{
  $Silki::Help::File::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use File::Slurp qw( read_file );
use HTML::Entities qw( encode_entities );
use HTML::Mason::Interp;
use Silki::Types qw( ArrayRef File HashRef Str );

use Moose;
use MooseX::SemiAffordanceAccessor;

has file => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

has locale_code => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has content => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_content',
);

sub _build_content {
    my $self = shift;

    my $config = Silki::Config->instance();

    my %config = (
        comp_root => $self->file()->dir()->stringify(),
        data_dir =>
            $config->cache_dir()
            ->subdir( 'mason', 'help', $self->locale_code() )->stringify(),
        error_mode           => 'fatal',
        in_package           => 'Silki::Mason::Help',
        default_escape_flags => 'h',
    );

    if ( $config->is_production() ) {
        $config{static_source} = 1;
        $config{static_source_touch_file}
            = $config->etc_dir()->file('mason-touch')->stringify();
    }

    my $body   = q{};
    my $interp = HTML::Mason::Interp->new(
        out_method => \$body,
        %config,
    );

    $interp->exec( q{/} . $self->file()->basename() );

    return $body;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A single help file

__END__
=pod

=head1 NAME

Silki::Help::File - A single help file

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

