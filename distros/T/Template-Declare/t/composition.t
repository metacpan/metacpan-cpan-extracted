use warnings;
use strict;

# Tests for the "Template Composition" doc examples.

##############################################################################
    package MyApp::UtilTemplates;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    template content => sub {
        my $self  = shift;
        my @paras = @_;
        h1 { $self->get_title };
        div {
            id is 'content';
            p { $_ } for @paras;
        };
    };

    package MyApp::Templates;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    mix MyApp::UtilTemplates under '/util';

    sub get_title { 'Kashmir' }

    template story => sub {
        my $self = shift;
        html {
          head {
              title { "My Site: " . $self->get_title };
          };
          body {
              show( 'util/content' => 'fist paragraph', 'second paragraph' );
          };
        };
    };

##############################################################################

package main;
use Test::More tests => 3;

    Template::Declare->init( dispatch_to => ['MyApp::Templates'] );
    is +Template::Declare->show('story'), q{
<html>
 <head>
  <title>My Site: Kashmir</title>
 </head>
 <body>
  <h1>Kashmir</h1>
  <div id="content">
   <p>fist paragraph</p>
   <p>second paragraph</p>
  </div>
 </body>
</html>}, 'Should get mixed in template output';

##############################################################################

    package MyApp::UI::Stuff;
    use Template::Declare::Tags;
    use base 'Template::Declare';

    sub img_path { '/ui/css' }

    template sidebar => sub {
        my ($self, $thing) = @_;
        div {
            class is 'sidebar';
            img { src is $self->img_path . '/sidebar.png' };
            p { $_->content } for $thing->get_things;
        };
    };

    package MyApp::UI::Stuff::Politics;
    use Template::Declare::Tags;
    use base 'MyApp::UI::Stuff';

    sub img_path { '/politics/ui/css' }

    package MyApp::Render;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    alias MyApp::UI::Stuff under '/stuff';

    template page => sub {
        my ($self, $page) = @_;
        h1 { $page->title };
        for my $thing ($page->get_things) {
            if ($thing->is('paragraph')) {
                p { $thing->content };
            } elsif ($thing->is('sidebar')) {
                show( '/stuff/sidebar' => $thing );
            }
        }
    };

    package MyApp::Render::Politics;
    use Template::Declare::Tags;
    use base 'Template::Declare';
    alias MyApp::UI::Stuff::Politics under '/politics';

    template page => sub {
        my ($self, $page) = @_;
        h1 { $page->title };
        for my $thing ($page->get_things) {
            if ($thing->is('paragraph')) {
                p { $thing->content };
            } elsif ($thing->is('sidebar')) {
                show( '/politics/sidebar' => $thing );
            }
        }
    };

    package My::Thing;
    sub new { my $self = shift; bless {@_} => $self }
    sub title { shift->{title} };
    sub content { shift->{content} };
    sub get_things { @{ shift->{things} } };
    sub is { shift->{is} eq shift };

    package main;

    my $page = My::Thing->new(
        title => 'My page title',
        things => [
            My::Thing->new( is => 'paragraph', content => 'Page paragraph' ),
            My::Thing->new(
                is => 'sidebar',
                things => [
                    My::Thing->new( content => 'Sidebar paragraph' ),
                    My::Thing->new( content => 'Another paragraph' ),
                ],
            )
        ],
    );

    Template::Declare->init( dispatch_to => ['MyApp::Render'] );
    is +Template::Declare->show( page => $page ), q{
<h1>My page title</h1>
<p>Page paragraph</p>
<div class="sidebar">
 <img src="/ui/css/sidebar.png" />
 <p>Sidebar paragraph</p>
 <p>Another paragraph</p>
</div>}, 'Should get page with default sidebar';


    Template::Declare->init( dispatch_to => ['MyApp::Render::Politics'] );
    is +Template::Declare->show( page => $page ), q{
<h1>My page title</h1>
<p>Page paragraph</p>
<div class="sidebar">
 <img src="/politics/ui/css/sidebar.png" />
 <p>Sidebar paragraph</p>
 <p>Another paragraph</p>
</div>}, 'Should get page with politics sidebar';


