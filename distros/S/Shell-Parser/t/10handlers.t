use strict;
use Test;
BEGIN { plan tests => 24 }
use Shell::Parser;

my $parser = new Shell::Parser;

my @handlers = qw(metachar keyword builtin command assign variable text comment);

# check that, at creation, no handler is affected
for my $handler (@handlers) {
    ok( $parser->{handler}{$handler}, undef                     ); #01-08
}

# now assign the default handler and check that all handlers have the same value
sub default_handler {}
$parser->handlers(default => \&default_handler);
for my $handler (@handlers) {
    ok( $parser->{handler}{$handler}, \&default_handler            ); #09-16
}

# now assign each handler, using the several ways allowed by handlers()
sub metachar_handler {}
$parser->handlers(metachar => \&metachar_handler);
ok( $parser->{handler}{metachar}, \&metachar_handler               ); #17

sub keyword_handler {}
$parser->handlers(keyword => \&keyword_handler);
ok( $parser->{handler}{keyword}, \&keyword_handler                 ); #18

sub builtin_handler {}
sub command_handler {}
sub assign_handler {}
$parser->handlers(builtin => \&builtin_handler, 
    command => \&command_handler, assign => \&assign_handler);
ok( $parser->{handler}{builtin}, \&builtin_handler                 ); #19
ok( $parser->{handler}{command}, \&command_handler                 ); #20
ok( $parser->{handler}{assign}, \&assign_handler                   ); #21

sub variable_handler {}
sub text_handler {}
sub comment_handler {}
$parser->handlers({variable => \&variable_handler, text => \&text_handler, 
    comment => \&comment_handler});
ok( $parser->{handler}{variable}, \&variable_handler               ); #22
ok( $parser->{handler}{text}, \&text_handler                       ); #23
ok( $parser->{handler}{comment}, \&comment_handler                 ); #24
