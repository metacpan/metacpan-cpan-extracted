package Mojolicious::Plugin::ProRenderer;
{
  $Mojolicious::Plugin::ProRenderer::VERSION = '0.40';
}

use strict;
use warnings;
use v5.10;

use base 'Mojolicious::Plugin';
use HTML::Template::Pro ();

__PACKAGE__->attr('pro');

# register plugin
sub register {
    my ($self, $app, $args) = @_;

    $args ||= {};

    # $args{template_options}{path} = [ './templates']
    $args->{template_options}{path} = $app->{renderer}{paths}
        unless exists $args->{template_options}{path};

    my $template = $self->build(%$args, app => $app);

    # Add "pro" handler
    $app->renderer->add_handler(pro => $template);

}

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

    # Inline
    my $inline = $options->{inline};

    # Template
    my $template = $renderer->template_name($options);
    $template = 'inline' 
        if defined $inline;

    warn "render template: $template"
        if $self->pro->{debug};  

    unless ($template) {
        $$output = 'some error happen!';
        return 0;        
    }
      
    # try to get content
    my $content = eval {
       my $t = HTML::Template::Pro->new(
           filename            => $template,
           # die_on_bad_params   => 1,
           %{$self->pro // {} }
        );

        # filter mojo.* variables
        my %params = map { $_ => $c->stash->{$_} } 
            grep !/mojo/, keys %{$c->stash};

        $t->param({%params, c => $c});
        $t->output();
    };

    # write error message to STDERR if eval fails
    # and return with false
    if($@ and $self->pro->{debug}) {
        warn "ERROR: $@";
        return 0;
    }

    # return false if content empty
    unless ($content) {
        # write error message to output
        $$output = "error while processing template: $template";
        return 1;
    }
    
    # assign content to $output ref 
    $$output = $content;
    
    # and return with true (success)
    return 1;
}

=head1 NAME

Mojolicious::Plugin::ProRenderer - HTML::Tempate::Pro render plugin for Mojolicious

=head1 VERSION

Version 0.40

=head1 SYNOPSIS

Add the handler:

    *Mojolicious*
  
    sub startup {
       ...
       $self->plugin('pro_renderer');
       ...
    }

    in controller:

    $self->render(
        message => 'test', 
        list    => [
          { id => 1 }, 
          { id => 2 }
        ]
    );
    
    *Mojolicious::Lite*
    ...
    plugin pro_renderer; 
    ...
    # or with options:
    plugin pro_renderer => {
	  template_options => {
	    debug => 1,
	    ...
	  }
    };
    
=head2 OPTIONS

  options are the same as in HTML::Template::Pro constructor, added only debug

=head1 FUNCTIONS

=head2 build

  create handler for renderer

=head2 register

  register plugin 'pro_renderer'

=head1 ATTRIBUTES

=head2 pro

  create attribute, containing template options

=head1 AUTHOR

Sergey Lobin, C<< <ifitwasi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-prorenderer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-ProRenderer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::ProRenderer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-ProRenderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-ProRenderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-ProRenderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-ProRenderer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sergey Lobin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Mojolicious::Plugin::ProRenderer
