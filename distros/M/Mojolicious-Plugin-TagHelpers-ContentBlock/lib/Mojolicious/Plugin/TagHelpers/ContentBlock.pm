package Mojolicious::Plugin::TagHelpers::ContentBlock;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/trim deprecated/;
use Mojo::ByteStream 'b';

our $VERSION = '0.11';

# TODO:
#   When a named contentblock is in the
#   configuration and in the init hash,
#   merge the values instead of overwriting.


# Sort based on the manual given position
# or the order the element was added
sub _position_sort {

  # Sort by manual positions
  if ($a->{position} < $b->{position}) {
    return -1;
  }
  elsif ($a->{position} > $b->{position}) {
    return 1;
  }

  # Manual positions are even, check order
  # of addition
  elsif ($a->{position_b} < $b->{position_b}) {
    return -1;
  }
  elsif ($a->{position_b} > $b->{position_b}) {
    return 1;
  };
  return 0;
};


# Register the plugin
sub register {
  my ($self, $app, $param) = @_;

  $param ||= {};

  # Load parameter from Config file
  if (my $c_param = $app->config('TagHelpers-ContentBlock')) {
    foreach (keys %$c_param) {

      # block already defined
      if (defined $param->{$_}) {
        if (ref $param->{$_} eq 'HASH') {
          $param->{$_} = [$param->{$_}];
        };

        # Push configuration parameter to given block
        push @{$param->{$_}},
          ref $c_param->{$_} eq 'HASH' ? $c_param->{$_} : @{$c_param->{$_}};
      }

      # Newly defined
      else {
        $param->{$_} = $c_param->{$_};
      }
    };
  };

  # Store content blocks issued from plugins
  my %content_block;

  # Add elements to a content block
  $app->helper(
    content_block => sub {
      my $c = shift;
      my $name = shift;

      # Get the last element as a template callback
      my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

      # Block information passed as a hashref
      my $block = ref $_[-1] eq 'HASH' ? pop : undef;

      # Receive all other parameters
      my %hparam = @_;

      # Set callback parameter
      if ($cb) {
        $block //= {};
        $block->{cb} = $cb;
      };

      # Potential legacy treatment
      # REMOVE in future version
      if (@_) {

        my $legacy = 0;

        # TODO: Legacy code for non-hash parameters
        if ($hparam{template}) {
          $block //= {};
          $block->{template} = delete $hparam{template};
          $legacy++;
        }

        # TODO: Legacy code for non-hash parameters
        elsif ($hparam{inline}) {
          $block //= {};
          $block->{inline} = delete $hparam{inline};
          $legacy++;
        };

        # TODO: Legacy code for non-hash parameters
        if ($hparam{position}) {
          return unless $block;
          $block->{position} = delete $hparam{position};
          $legacy++;
        };

        deprecated 'ContentBlocks: Passing block parameters as a list is deprecated' if $legacy;
      };

      # No block passed - return content block
      unless ($block) {
        my $string = '';

        # TODO:
        #   This may be optimizable - by sorting in advance and possibly
        #   attaching compiled templates all the way. The only problem is the
        #   difference between application called contents and controller
        #   called contents.

        # The blocks are based on elements from the global
        # hash and from the stash
        my @blocks;
        @blocks = @{$content_block{$name}} if $content_block{$name};
        if ($c->stash('cblock.'. $name)) {
          push(@blocks, @{$c->stash('cblock.'. $name)});
        };

        my $sep = $hparam{separator};

        # Iterate over default and stash content blocks
        foreach (sort _position_sort @blocks) {

          my $value;

          # Render inline template
          if ($_->{inline}) {
            $value = $c->render_to_string(inline => $_->{inline}) // '';
          }

          # Render template
          elsif ($_->{template}) {
            $value = $c->render_to_string(template => $_->{template}) // '';
          }

          # Render callback
          elsif ($_->{cb}) {
            $value = $_->($c) // '';
          };

          # There is a defined block
          if ($value) {

            # Add separator if needed
            $string .= $sep if $string && $sep;
            $string .= trim $value;
          };
        };

        # Return content block
        return b($string);
      };

      # Content block not yet defined
      $content_block{$name} ||= [];

      # Two position definitions - first manually defined,
      # the second based on the position in the block
      $block->{position} //= 0;
      $block->{position_b} = scalar @{$content_block{$name}};

      # Called from controller
      if ($c->tx->{req}) {

        # Add template to content block
        push(@{$c->stash->{'cblock.' . $name} ||= []}, $block);
      }

      # Probably called from app
      else {

        # Add template to content block
        push(@{$content_block{$name}}, $block);
      };
    }
  );

  # Check, if the content block has any elements
  $app->helper(
    content_block_ok => sub {
      my ($c, $name) = @_;

      # Negative
      return unless $name;

      # Positive
      if ($content_block{$name}) {
        return 1 if @{$content_block{$name}};
      };

      # Positive
      return 1 if $c->stash('cblock.'. $name);

      # Negative
      return;
    }
  );

  # Iterate over all parameters
  while (my ($name, $value) = each %$param) {

    # Only a single block
    if (ref $value eq 'HASH') {
      $app->content_block($name => $value);
    }

    # Multiple blocks for this name
    elsif (ref $value eq 'ARRAY') {
      foreach (@$value) {
        $app->content_block($name => $_);
      };
    };
  };
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::TagHelpers::ContentBlock - Mojolicious Plugin for Content Blocks


=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin 'TagHelpers::ContentBlock';

  # Add snippets to a named content block, e.g. from a plugin
  app->content_block(
    admin => {
      inline => "<%= link_to 'Edit' => '/edit' %>"
    }
  );

  # ... or in a controller:
  get '/' => sub {
    my $c = shift;
    $c->content_block(
      admin => {
        inline => "<%= link_to 'Logout' => '/logout' %>",
        position => 20
       }
    );
    $c->render(template => 'home');
  };

  app->start;

  __DATA__
  @@ home.html.ep
  %# and call it in a template
  %= content_block 'admin'

=head1 DESCRIPTION

L<Mojolicious::Plugin::TagHelpers::ContentBlock> is a L<Mojolicious> plugin
to create pluggable content blocks for page views.


=head1 METHODS

L<Mojolicious::Plugin::TagHelpers::ContentBlock> inherits all methods from
L<Mojolicious::Plugin> and implements the following new one.


=head2 register

  # Mojolicious
  $app->plugin('TagHelpers::ContentBlock');

  # Mojolicious::Lite
  plugin 'TagHelpers::ContentBlock';

Called when registering the plugin.
Accepts an optional hash containing information
on content blocks to be registered on startup.

  # Mojolicious
  $app->plugin(
    'TagHelpers::ContentBlock' => {
      admin => [
        {
          inline => '<%= link_to "Edit" => "/edit" %>',
          position => 10
        },
        {
          inline => '<%= link_to "Logout" => "/logout" %>',
          position => 15
        }
      ],
      footer => {
        inline => '<%= link_to "Privacy" => "/privacy" %>',
        position => 5
      }
    }
  );

Content blocks are defined by their name followed by
either a hash of content block information or an array
of content block information hashes.
See L<content_block> for further information.

The content block hash can be set as part
of the configuration file with the key C<TagHelpers-ContentBlock> or
on registration (that will be merged with the configuration).


=head1 HELPERS

=head2 content_block

  # In a plugin
  $app->content_block(
    admin => {
      inline => '<%= link_to 'Edit' => '/edit' %>'
    }
  );

  # From a controller
  $c->content_block(
    admin => {
      inline => '<%= link_to 'Edit' => '/edit' %>',
      position => 40
    }
  );

  # From a template
  % content_block 'admin', { position => 9 }, begin
    <%= link_to 'Edit' => '/edit' %>
  % end

  # Calling the content block
  %= content_block 'admin'

Add content to a named content block (like with
L<content_for|Mojolicious::Plugin::DefaultHelpers/content_for>)
or call the contents from a template.

In difference to L<content_for|Mojolicious::Plugin::DefaultHelpers/content_for>,
content of the content block can be defined in a global cache during
startup or as part of the applications configuration.

Supported content block parameters, passed as a hash, are C<template> or C<inline>.
Additionally a numeric C<position> value can be passed, defining the order of elements
in the content block. If C<position> is omitted,
the default position is C<0>. Position values may be positive or negative.

When calling the content blocks, an additional list parameter L<separator>
can define a string to be placed between all blocks.

  # Calling the content block
  %= content_block 'admin', separator => '<hr />'


=head2 content_block_ok

  # In a template
  % if (content_block_ok('admin')) {
    <ul>
    %= content_block 'admin'
    </ul>
  % };

Check if a C<content_block> contains elements.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-TagHelpers-ContentBlock


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.


=cut
