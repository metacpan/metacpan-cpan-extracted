#!/usr/bin/perl

# This is a simple number guessing game.  It's primary purpose is to
# show how the error handling works.  It keeps making the 'numbers'
# primary loop over and over until the user guesses the value randomly
# chosen.  Note that the user can cheat in HTML by looking at the HTML
# output since it contains the random value passed as a hidden field.

# The user must then guess numbers from 1 to 10 till they get it right
# after which the results are logged to a file in /tmp.  (Note that
# cheating with this over HTML is easy, as the answer is encoded into
# the HTML sent to the user).


use QWizard;

# to use this as both a tk and a CGI script, this must be writable by
# all users and including the user the web server runs as.
$scorefile="/tmp/numbers-scores";

my %primaries =
  ('top' => 
   { title     =>  'Would you like to play a game?',
     questions =>
     [ { type => 'text',
	 name => 'user',
	 text => "Enter your name:"
       },
       {
	type => 'radio',
	name => 'game',
	text => 'Select a game:',
	labels => ["numbers", "Guess a number",
		   "numbers_high_score", "Show the high score table"],
       }],
     post_answers => [sub {
			  my $wiz = shift;
			  $wiz->add_todos(qwparam('game'));
			  return 'OK';
		      }]
   },

   'numbers_high_score' =>
   { title => 'The high score table for the numbers guessing game',
     questions =>
     [{ type => 'table',
	text => 'high scores:',
	headers => [[qw(Name Difficulty Score)]],
	values => sub {
	    my @scores;
	    open(I,"$scorefile");
	    while (<I>) {
		push @scores, [split()];
	    }
	    return [\@scores];
	},
	doif => sub {return -f $scorefile},
      },
      { type => 'label',
	text => 'High scores:',
	values => 'No high scores yet',
	doif => sub {return ! -f $scorefile},
      }],
   },

   'numbers' =>
   { title        => "Pick a number range to play from.",
     introduction => "Lets play a guessing game.  I'm going to think of a number between 1 and the number you pick below.  Then you'll have to guess it.  But first pick a number below to set the difficultly level.",
     questions => 
     [
      { type => 'radio',
	name => 'difficulty',
	values => [qw(10 20 50)]
      }
     ],
     sub_modules => ['numbers_doit']},

   'numbers_doit' =>
   { title => "Guess the number I'm thinking of!",
     questions => 
     [{ type => 'hidden',
	name => 'answer',
	values => [sub { qwparam('answer') || int(rand(qwparam('difficulty')) + 1) }],
      },
      { type => 'hidden',
	name => 'tries',
	values => 1,
      },
      { type => 'text',
	name => 'guess',
	text => 'what is your guess',
	helptext => 'The computer is thinking of a number.  Please try and guess the number.  It will tell you when you are high and low and keep track of how many attempts have been made to guess it.',
	default => sub { qwparam('guess') || '' },
	check_value => sub {
	    if (qwparam('guess') > qwparam('answer')) {
	        qwparam('tries',qwparam('tries') + 1);
		return "Your guess, " . qwparam('guess') . ", was too high!"
	    }
	    elsif (qwparam('guess') < qwparam('answer')) {
	        qwparam('tries',qwparam('tries') + 1);
		return "Your guess, " . qwparam('guess') . ",  was too low!"
	    }
	}
      },
     ],
     actions_descr => [ 'High score entry: @user@ guessed a number between 1 and @difficulty@ in @tries@ tries' ],

     # save the high score!
     actions => [ [sub {
		       open(O,">>$scorefile");
		       print O qwparam('user'),"\t",qwparam('difficulty'),"\t",qwparam('tries'),"\n";
		       close(O);
		       return 'OK';
		   }],
		  'msg: Score for @user@ of @tries@ logged']
   }
  );

my $wiz = new QWizard(primaries => \%primaries,
		      title => "The Games Wizard");

# $QWizard::qwdebug = 1;

$wiz->magic('top');
