#!perl -wT
# $Id: basic.t 996 2005-12-03 01:37:51Z claco $
use strict;
use warnings;
use Test::More;

plan tests => 6;

use_ok("Carp");
use_ok("Net::Blogger");
use_ok("Term::ReadKey");

my $blogger = undef;
my $success = 0;


TODO: {
    todo_skip 'Move live API tests to another test file', 3;

    my $debug = &ask_yesno("Enable debugging output");
    diag("debugging is ".(($debug) ? "enabled" : "disabled" )."\n");

    $blogger  = Net::Blogger->new(debug=>$debug);

    isa_ok($blogger,"Net::Blogger");

    $blogger->Proxy(&ask("URI of a working Blogger API server"));
    $blogger->Username(&ask("Username"));
    $blogger->Password(&ask_password());
    $blogger->AppKey(&ask("App key (optional)"));

    my $id = $blogger->GetBlogId(blogname=>&ask("Blog name"));

    ok($blogger->BlogId($id));

    my $post    = &ask("Please enter some text");
    my $publish = &ask_yesno("Publish this text");

    my $ok = $blogger->newPost(postbody => \$post,
                   publish  => $publish);

    if (! $ok) {
       diag("New post failed, the Blogger API server reported the following error:\n".
        $blogger->lastError()."\n");
    }

    ok($ok);

    #

    sub ask_yesno {
      my $question = shift;

      &diag("\n$question? [y/n] ");

      my $answer = <STDIN>;
      chomp $answer;

      return ($answer =~ /^y(es)*$/i) ? 1 : 0;
    }

    sub ask {
      my $question = shift;
      &diag("\n$question ? ");

      my $answer = <STDIN>;
      chomp $answer;
      return $answer;
    }

    sub ask_password {
        my $pass = undef;

        my $prompt = "\nPlease enter password";

        while (! $pass) {

          &diag("$prompt: ");

          &Term::ReadKey::ReadMode("noecho");
          $pass = &Term::ReadKey::ReadLine(0);
          chomp $pass;

          &Term::ReadKey::ReadMode("normal");
          &diag("\n");
        }

        return $pass;
    }
};
