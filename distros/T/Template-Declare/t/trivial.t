use warnings;
use strict;


package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 9;

template simple => sub {

html { 
    head { }
        body {
            show 'content'
        }
}

};

template content => sub {
        div { attr { id => 'body' }
            outs('This is my content')
        }

};


sub  wrap {
    my ( $title, $coderef) = (@_);
    outs_raw '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
        with ( xmlns      => "http://www.w3.org/1999/xhtml", 'xml:lang' => "en"), 
    html {
        head {
            meta { attr { 'http-equiv' => "content-type", 'content' => "text/html; charset=utf-8" } }
            meta { attr { name => 'robots', content => 'all' } }
            title { outs($title) }
            }
        body {
            $coderef->(); 
        }
            
        }
};

template markup => sub {
    my $self = shift;
    wrap(
        'My page!',
        sub {

            with( id => 'syntax' ), div {
                div {
                    a { attr { href => '#', onclick => "Element.toggle('syntax_content');return(false);" }
                        b {'Wiki Syntax Help'}
                    }
                };
                with( id => 'syntax_content' ), div {
                    h3   {'Phrase Emphasis'}
                    code {
                        b { '**bold**' }
                        i {'_italic_'}
                    }

                    h3 {'Links'}

                    code {'Show me a [wiki page](WikiPage)'}
                    code {'An [example](http://url.com/ "Title")'}
                    h3   {'Headers'}
                    pre  {
                        code {
                            join( "\n",
                                '# Header 1',
                                '## Header 2',
                                '###### Header 6' )
                            }
                    }
                    h3  {'Lists'}
                    p   {'Ordered, without paragraphs:'}
                    pre {
                        code { join( "\n", '1.  Foo', '2.  Bar' ) }
                    }
                    p   {'Unordered, with paragraphs:'}
                    pre {
                        code {
                            join( "\n",
                                '*   A list item.',
                                'With multiple paragraphs.',
                                '*   Bar' )
                            }
                    }
                    h3 {'Code Spans'}

                    p {
                        code {'`&lt;code&gt;`'}
                            . 'spans are delimited by backticks.'
                    }

                    h3 {'Preformatted Code Blocks'}

                    p {
                        'Indent every line of a code block by at least 4 spaces.'
                    }

                    pre {
                        code {
                            'This is a normal paragraph.' . "\n\n" . "\n"
                                . '    This is a preformatted' . "\n"
                                . '    code block.'
                        }
                    }

                    h3 {'Horizontal Rules'}

                    p {
                        'Three or more dashes: ' . code {'---'}
                    }

                    address {
                        '(Thanks to <a href="http://daringfireball.net/projects/markdown/dingus">Daring Fireball</a>)'
                        }
                    }
            }
            script {
                qq{
   // javascript flyout by Eric Wilhelm
   // TODO use images for minimize/maximize button
   // Is there a way to add a callback?
   Element.toggle('syntax_content')
   }
            }
        }
    )
};

package Template::Declare::Tags;
require "t/utils.pl";
use Test::More;

our $self;
local $self = {};
bless $self, 'Wifty::UI';

Template::Declare->init( dispatch_to => ['Wifty::UI']);

{
Template::Declare->buffer->clear;
my $simple =(show('simple'));
ok($simple =~ 'This is my content', "show fucntion returned context ");
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
my $simple =Template::Declare->show('simple');
ok($simple =~ 'This is my content', "T::D->show returns a string");
#diag ($simple);
ok_lint($simple);
}
{
Template::Declare->buffer->clear;
 Template::Declare->show('simple');
ok(Template::Declare->buffer->data() =~ 'This is my content', "show simple filled the buffer");
#diag ($simple);
ok_lint(Template::Declare->buffer->data());
}
{
Template::Declare->buffer->clear;
my $out =  (show('markup'));
#diag($out);
my @lines = split("\n",$out);

ok($out =~ /Fireball/, "We found fireball in the output");
my $count = grep { /Fireball/} @lines;
is($count, 1, "Only found one");
ok_lint($out);

}


1;
