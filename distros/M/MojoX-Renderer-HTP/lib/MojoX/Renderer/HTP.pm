package MojoX::Renderer::HTP;

use warnings;
use strict;
use Carp;

use base 'Mojo::Base';

use HTML::Template::Pro ();

=head1 NAME

MojoX::Renderer::HTP - HTML::Tempate::Pro renderer for Mojo

=head1 VERSION

Version 0.032

=cut

our $VERSION = '0.032';
__PACKAGE__->attr('pro' => 1);

=head1 SYNOPSIS

Add the handler:

    use MojoX::Renderer::HTP;

    sub startup {
       ...

       my $pro = MojoX::Renderer::HTP->build(
            mojo => $self,
    		template_options => {
    			path 			=> [ $self->home->rel_dir('templates') ], 		
    		}

       );

       $self->renderer->add_handler( pro => $pro );
       
       $self->renderer->default_handler('pro');
    }

Then in controller:

   $self->render(
        message => 'test', 
        list    => [{id => 1}, { id=>2 }]
   );

=head1 FUNCTIONS

=head2 build

create handler for renderer

=cut

sub build {
    my $self = shift->SUPER::new(@_);
    $self->_init(@_);
    return sub { $self->_render(@_) }
}

sub _init {
    my $self = shift;
    my %args = @_;

    my $mojo = delete $args{mojo};

    # now we only remember options 
    $self->pro($args{template_options});

    return $self;
}

sub _render {
    my ($self, $renderer, $c, $output, $options) = @_;

    # get template name from controller 
    my $template = $c->stash->{template};

    # if not set get it from options
    $template = $renderer->template_path($options)
        unless $template;

    # try to get content
    my $content = eval {
	   my $t = HTML::Template::Pro->new(
	       filename            => $template,
	       die_on_bad_params   => 1,
	       %{$self->pro}
        );
    
        $t->param({%{$c->stash}, c => $c});
        $t->output();
    };

    # write error message to log if eval fails
    # and return with false
    if($@) {
        warn "MojoX::Renderer::HTP ERROR: $@";
        return 0;
    }

    # return false if content empty
    return 0
        unless $content;
    
    # assign content to $output ref 
    $$output = $content;
    
    # and return with true (success)
    return 1;
}

=head1 AUTHOR

Sergey Lobin, C<< <ifitwasi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-renderer-htp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Renderer-HTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Renderer::HTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Renderer-HTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Renderer-HTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-HTP>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-HTP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Sergey Lobin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MojoX::Renderer::HTP
