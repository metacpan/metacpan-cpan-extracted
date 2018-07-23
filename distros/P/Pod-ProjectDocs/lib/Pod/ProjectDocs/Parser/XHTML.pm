package Pod::ProjectDocs::Parser::XHTML;

use strict;
use warnings;

our $VERSION = '0.52';    # VERSION

use base qw(Pod::Simple::XHTML);

use File::Basename();
use File::Spec();
use HTML::Entities()
  ;    # Required for proper entity detection in Pod::Simple::XHTML.

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->perldoc_url_prefix('http://metacpan.org/module/');

    return $self;
}

sub doc {
    my ( $self, $doc ) = @_;

    if ( defined $doc ) {
        $self->{_doc} = $doc;
    }

    return $self->{_doc};
}

sub local_modules {
    my ( $self, $modules ) = @_;

    if ( defined $modules ) {
        $self->{_local_modules} = $modules;
    }

    return $self->{_local_modules};
}

sub current_files_output_path {
    my ( $self, $path ) = @_;

    if ( defined $path ) {
        $self->{_current_files_output_path} = $path;
    }

    return $self->{_current_files_output_path};
}

sub resolve_pod_page_link {
    my ( $self, $module, $section ) = @_;

    my %module_map = %{ $self->local_modules() || {} };

    if ( $module && $module_map{$module} ) {
        $section = defined $section ? '#' . $self->idify( $section, 1 ) : '';
        my ( $filename, $directory ) =
          File::Basename::fileparse( $self->current_files_output_path,
            qr/\.html/ );
        return File::Spec->abs2rel( $module_map{$module}, $directory )
          . $section;
    }

    return $self->SUPER::resolve_pod_page_link( $module, $section );

}

#
# Function overrides to extract the Pod page description, e.g.
#
#   =head1 Name
#
#   Package::Name - Description line.
#
# The code also takes into account complex POD in the description line, like L<> tags.
#
sub start_head1 {
    my ( $self, $attrs ) = @_;

    $self->{_in_head1} = 1;
    return $self->SUPER::start_head1($attrs);
}

sub end_head1 {
    my ( $self, $attrs ) = @_;

    delete $self->{_in_head1};
    return $self->SUPER::end_head1($attrs);
}

sub handle_text {
    my ( $self, $text ) = @_;

    # Are we after =head1 NAME?
    if ( $self->{_titleflag} ) {

# Remember the line number if not yet set - this means we just endered this line.
        if ( !$self->{_titleline} ) {
            $self->{_titleline} = $self->{line_count};
        }

# All nodes within this line will be processed, and their text added to the final description.
        if ( $self->{line_count} == $self->{_titleline} ) {
            $self->{_description} .= $text;
        }

        # Once we leave this line, turn off the title flag again.
        else {
            delete $self->{_titleflag};
        }
    }
    elsif ( $self->{_in_head1} && $text eq 'NAME' ) {
        $self->{_titleflag} = 1;
    }

    return $self->SUPER::handle_text($text);
}

sub DESTROY {
    my $self = shift;

    # At the end - process and store the description.
    if ( $self->{_description} ) {

        my ( $name, $description ) =
          $self->{_description} =~ m{ ^ \s* ([^-]*?) \s* - \s* (.*?) \s* $}x;

        if ( $description && $self->doc() ) {
            $self->doc()->title($description);
        }
    }
    return;
}

1;
