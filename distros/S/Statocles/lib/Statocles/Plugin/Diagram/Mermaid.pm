package Statocles::Plugin::Diagram::Mermaid;
our $VERSION = '0.091';
# ABSTRACT: Render diagrams using mermaid https://mermaidjs.github.io

#pod =head1 SYNOPSIS
#pod
#pod     # --- Configuration
#pod     # site.yml
#pod     ---
#pod     site:
#pod         class: Statocles::Site
#pod         args:
#pod             plugins:
#pod                 diagram:
#pod                     $class: Statocles::Plugin::Diagram::Mermaid
#pod
#pod     # --- Usage
#pod     <%= diagram mermaid => begin %>
#pod     sequenceDiagram
#pod     loop every day
#pod         Alice->>John: Hello John, how are you?
#pod         John-->>Alice: Great!
#pod     end
#pod     <% end %>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin adds the C<diagram> helper function to all templates and
#pod content documents, allowing for creation of L<mermaid|https://mermaidjs.github.io>
#pod diagrams.
#pod
#pod =cut

use Mojo::URL;
use Statocles::Base 'Class';
with 'Statocles::Plugin';


#pod =attr mermaid_url
#pod
#pod Set the url to use as a, possibly local, alternative to the default script
#pod L<mermaid.min.js|https://unpkg.com/mermaid/dist/mermaid.min.js> for including in
#pod a script tag.
#pod
#pod =cut

has mermaid_url => (
  is => 'ro',
  isa => InstanceOf['Mojo::URL'],
  default => sub { Mojo::URL->new('https://unpkg.com/mermaid/dist/mermaid.min.js') },
  coerce => sub {
      my ( $args ) = @_;
      return Mojo::URL->new( $args );
  },
);


#pod =method diagram
#pod
#pod     %= diagram $type => $content
#pod
#pod Wrap the given C<$content> with the html for displaying the diagram with
#pod C<mermaid.js>.
#pod
#pod In most cases displaying a diagram will require the use of C<begin>/C<end>:
#pod
#pod     %= diagram mermaid => begin
#pod     graph TD
#pod     A[Christmas] -->|Get money| B(Go shopping)
#pod     B --> C{Let me think}
#pod     C -->|One| D[Laptop]
#pod     C -->|Two| E[iPhone]
#pod     C -->|Three| F[Car]
#pod     % end
#pod
#pod =cut

# https://unpkg.com/mermaid@7.1.0/dist/mermaid.min.js
# <script src="./mermaid.min.js"></script>
#   <script>
#     mermaid.initialize({startOnLoad: true, theme: 'forest'});
#   </script>
sub mermaid {
  my ($self, $args, @args) = @_;
  my ( $text, $type ) = ( pop @args, pop @args );

  # Handle Mojolicious begin/end
  if ( ref $text eq 'CODE' ) {
      $text = $text->();
      # begin/end starts with a newline, so remove it to prevent too
      # much top space
      $text =~ s/\n$//;
  }

  my $page = $args->{page} || $args->{self};
  if ( $page ) {
      # Add the appropriate stylesheet to the page
      my $mermaid_url = $self->mermaid_url->to_string;
      if ( !grep { $_->href eq $mermaid_url } $page->links( 'script' ) ) {
          $page->links( script => {href => $mermaid_url} );
          $page->links( script => {
            href => '',
            text => q|mermaid.initialize({startOnLoad: true, theme: 'forest'});|
          } );
      }
  }
  return qq{<div class="mermaid">$text</div>};
}

#pod =method register
#pod
#pod Register this plugin with the site. Called automatically.
#pod
#pod =cut

sub register {
    my ( $self, $site ) = @_;
    $site->theme->helper( diagram => sub { $self->mermaid( @_ ) } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Plugin::Diagram::Mermaid - Render diagrams using mermaid https://mermaidjs.github.io

=head1 VERSION

version 0.091

=head1 SYNOPSIS

    # --- Configuration
    # site.yml
    ---
    site:
        class: Statocles::Site
        args:
            plugins:
                diagram:
                    $class: Statocles::Plugin::Diagram::Mermaid

    # --- Usage
    <%= diagram mermaid => begin %>
    sequenceDiagram
    loop every day
        Alice->>John: Hello John, how are you?
        John-->>Alice: Great!
    end
    <% end %>

=head1 DESCRIPTION

This plugin adds the C<diagram> helper function to all templates and
content documents, allowing for creation of L<mermaid|https://mermaidjs.github.io>
diagrams.

=head1 ATTRIBUTES

=head2 mermaid_url

Set the url to use as a, possibly local, alternative to the default script
L<mermaid.min.js|https://unpkg.com/mermaid/dist/mermaid.min.js> for including in
a script tag.

=head1 METHODS

=head2 diagram

    %= diagram $type => $content

Wrap the given C<$content> with the html for displaying the diagram with
C<mermaid.js>.

In most cases displaying a diagram will require the use of C<begin>/C<end>:

    %= diagram mermaid => begin
    graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[Car]
    % end

=head2 register

Register this plugin with the site. Called automatically.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
