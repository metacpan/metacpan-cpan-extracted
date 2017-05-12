package Silki::View::Mason;
{
  $Silki::View::Mason::VERSION = '0.29';
}

use strict;
use warnings;

use base 'Catalyst::View::Mason';

{
    package Silki::Mason::Web;
{
  $Silki::Mason::Web::VERSION = '0.29';
}

    use Data::Dumper;
    use HTML::Entities qw( encode_entities );
    use Lingua::EN::Inflect qw( A PL_N );
    use Number::Format qw( format_bytes );
    use Silki::I18N qw( loc );
    use Silki::Util qw( string_is_empty english_list );
    use Silki::URI qw( dynamic_uri static_uri );
    use URI::Escape qw( uri_escape );
}

# used in templates
use HTML::FillInForm;
use Markdent::Simple::Fragment;
use Path::Class;
use Silki::Config;
use Silki::Web::Form;
use Silki::Web::FormData;
use Silki::Util qw( string_is_empty );

{
    my $config = Silki::Config->instance();

    my %config = (
        comp_root => $config->share_dir()->subdir('mason')->stringify(),
        data_dir =>
            $config->cache_dir()->subdir( 'mason', 'web' )->stringify(),
        error_mode           => 'fatal',
        in_package           => 'Silki::Mason::Web',
        use_match            => 0,
        default_escape_flags => 'h',
        escape_flags         => {
            nbsp => \&_nbsp_escape,
        },
    );

    if ( $config->is_production() ) {
        $config{static_source} = 1;
        $config{static_source_touch_file}
            = $config->etc_dir()->file('mason-touch')->stringify();
    }

    __PACKAGE__->config( \%config );
}

sub _nbsp_escape {
    ${ $_[0] } =~ s/ /&nbsp;/g;

    return;
}

# sub new
# {
#     my $class = shift;

#     my $self = $class->SUPER::new(@_);

# #    Silki::Util::chown_files_for_server( $self->template()->files_written() );

#     return $self;
# }

sub has_template_for_path {
    my $self = shift;
    my $path = shift;

    return -f file(
        $self->config()->{comp_root},
        ( grep { !string_is_empty($_) } split /\//, $path ),
    );
}

__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: A Mason-based view

__END__
=pod

=head1 NAME

Silki::View::Mason - A Mason-based view

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

