package Plack::Middleware::Debug::Notepad;
use strict;
use warnings;

our $VERSION = '0.12';
$VERSION = eval $VERSION;

use Text::Markdown;
use Text::MicroTemplate qw/ encoded_string /;
use Plack::Request;
use Plack::Util::Accessor qw( notepad_file );

use parent 'Plack::Middleware::Debug::Base';

sub prepare_app {
    my $self = shift;

    $self->notepad_file( '/tmp/plack-middleware-debug-notepad.md' )
        unless $self->notepad_file;
}

sub call {
    my ( $self, $env ) = @_;

    if ( $env->{ QUERY_STRING } =~ m/__plack_middleware_debug_notepad__/ ) {
        if ( $env->{ REQUEST_METHOD } eq 'POST' ) {
            return $self->save_markdown( $env );
        }
        elsif ( $env->{ REQUEST_METHOD } eq 'GET' ) {
            return [ 200, [ 'Content-Type', 'text/html' ], [ $self->get_markdown ] ];
        }
    }
    else {
        return $self->SUPER::call( $env );
    }
}

sub run {
    my ( $self, $env, $panel ) = @_;

    return sub {
        $panel->title( 'Notepad' );
        $panel->nav_title( 'Notepad' );
        $panel->nav_subtitle( 'things to keep in mind' );
        $panel->content( $self->get_notepad_content( $panel->dom_id ) );
    }
}

sub get_notepad_content {
    my $self = shift;
    my $id   = shift;

    my $md = $self->get_markdown;
    my $vars = {
        markdown => $md,
        id       => $id,
        rendered => encoded_string( Text::Markdown->new->markdown( $md ) ),
    };

    return Text::MicroTemplate->new( template => $self->the_template )->build->( $vars );
}

sub get_markdown {
    my $self = shift;

    if ( open my $fh, '<', $self->notepad_file ) {
        local $/;
        return <$fh>;
    }
    elsif ( ! -e $self->notepad_file ) {
        return 'Replace this with whatever you need to keep track of.';
    }
    else {
        return "Error opening your notepad file: $!";
    }
}

sub the_template {
    <<'EOTMPL' }
? my $stash = $_[0];
<style type="text/css">
    div#debug_<?= $stash->{ id } ?>_html { border: 1px solid black; background-color: white; padding: 4px; margin: 4px }
    div#debug_<?= $stash->{ id } ?>_html h1 { font-size: 16px }
    div#debug_<?= $stash->{ id } ?>_html h2 { font-size: 15px }
    div#debug_<?= $stash->{ id } ?>_html h3 { font-size: 14px; font-weight: 700 }
    div#debug_<?= $stash->{ id } ?>_html a:link { color: blue }
    div#debug_<?= $stash->{ id } ?>_html a:visited { color: #800080 }
    div#debug_<?= $stash->{ id } ?>_markdown textarea { width: 90%; height: 80%; padding: 4px; margin: 4px  }
    #debug_<?= $stash->{ id } ?>_html ul { list-style: disc outside; padding-left: 20px; }
    #debug_<?= $stash->{ id } ?> input { color: white; background-color: black; }
</style>
<div id="debug_<?= $stash->{ id } ?>">
    <script>
        jQuery( function( $j ) {
            function hide_editor() {
                $j('#debug_<?= $stash->{ id } ?>_markdown').toggle();
                $j('#debug_<?= $stash->{ id } ?>_html').toggle();
                $j('#edit_button_<?= $stash->{ id } ?>').toggle();
            }
            $j( '#cancel_button_<?= $stash->{ id } ?>' ).click( function() {
                hide_editor();
                $j.get( "?__plack_middleware_debug_notepad__", '', function( response ) {
                    $j('#debug_<?= $stash->{ id } ?>_markdown_edited').val( response );
                }, 'html' );
            });
            $j( '#edit_button_<?= $stash->{ id } ?>' ).click( function() {
                $j('#debug_<?= $stash->{ id } ?>_markdown').toggle();
                $j('#debug_<?= $stash->{ id } ?>_html').toggle();
                $j('#edit_button_<?= $stash->{ id } ?>').toggle();
            });
            $j( '#save_button_<?= $stash->{ id } ?>' ).click( function() {
                var data = { "markdown": $j( '#debug_<?= $stash->{ id } ?>_markdown_edited' ).val() };
                $j.post( "?__plack_middleware_debug_notepad__", data, function( response ) {
                    $j('#debug_<?= $stash->{ id } ?>_html').html( response );
                    hide_editor();
                }, 'html' );
            });
        })
    </script>
    <div id="debug_<?= $stash->{ id } ?>_markdown" style="display: none">
        <textarea rows="20" name="markdown" id="debug_<?= $stash->{ id } ?>_markdown_edited"><?= $stash->{ markdown } ?></textarea>
        <br>
        <input type="button" value="save" id="save_button_<?= $stash->{ id } ?>">
        <a target="_blank" href="http://daringfireball.net/projects/markdown/syntax">Syntax help</a>
        <input type="button" value="cancel" id="cancel_button_<?= $stash->{ id } ?>">
    </div>
    <div id="debug_<?= $stash->{ id } ?>_html">
?=      $stash->{ rendered }
    </div>
    <input type="button" value="edit" id="edit_button_<?= $stash->{ id } ?>">
</div>
EOTMPL

sub save_markdown {
    my $self = shift;
    my $env  = shift;

    my $md = Plack::Request->new( $env )->param( 'markdown' );

    my $response = eval {
        if ( open my $fh, '>', $self->notepad_file ) {
            print $fh $md;
            close $fh;
            return Text::Markdown->new->markdown( $md );
        }
        else {
            return "<h1>Error</h1><p>An error occured while trying to save your edited version: <pre>$!</pre></p>";
        }
    };

    return [ 200, [ 'Content-Type', 'text/html' ], [ $response ] ];
}

1;

__END__

=head1 NAME

Plack::Middleware::Debug::Notepad - Abuse the plack debug panel and keep your todo list in it.

=head1 SYNOPSIS

 # Using the default file path to store the contents of your notepad:
 builder {
     enable 'Debug', panels => [ qw( Environment Response Notepad ) ];
     $app;
 };

 # If you need to control the location of the file:
 return builder {
     enable 'Debug', panels => [ qw( Environment Response ) ];
     enable 'Debug::Notepad', notepad_file => '/some/path/some/file';
     $app;
 };

=head1 DESCRIPTION

This panel gives you a little notepad right in your browser. Edit its content using
markdown and have it rendered in html.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Currently, no kind of locking mechanism is used to protect the integrity
of your notepad. The rationale is that this module is supposed to be used
locally and therefore no concurrent write-requests should normally occur.

Please report any bugs or feature requests through the web interface at
L<https://github.com/mannih/Plack-Middleware-Debug-Notepad>.

=head1 AUTHOR

Manni Heumann, C<< <cpan@lxxi.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Manni Heumann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

