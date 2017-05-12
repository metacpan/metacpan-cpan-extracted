#!/usr/bin/perl

use QWizard;

my $old;

my %primaries=
(
 'top' =>
 { title => 'test',
   questions =>
   [
    { type => 'menu',
      name => 'setit',
      values => [qw(0 1 2 3 4 5)],
      default => sub { $old = 1; },
      submit => 1,
      check_value => sub {
	 print STDERR "check: ",qwparam('setit'),"\n";
	 if ($old and $old ne qwparam('setit')) {
	     print STDERR "   REDO\n";
	     $old = qwparam('setit');
	     qwparam('it', qwparam('setit'));
	     print STDERR "  set: ", qwparam('it'),"\n";
	     return 'REDISPLAY';
	 }
	return 'OK';
     }
    },
    {type => 'text',
     name => 'it',
     default => sub { 
	 print STDERR "def: ...", qwparam('it'), "\n";
	 return 'val1';
     },
    },
   ],
   post_answers => [sub {
			print STDERR "post: ",qwparam('it'),"\n";
			return (qwparam('it') eq '5' ? 'OK' : 'REDISPLAY');
		    }],
   actions => [sub {
		   print STDERR "act: ",qwparam('it'),"\n";
	       }],
 }
);


my $qw = new QWizard(primaries => \%primaries);
$qw->magic('top');
