#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 38;
use Parse::ErrorString::Perl;

my $parser = Parse::ErrorString::Perl->new;

# use strict;
# use warnings;
#
# $kaboom;

my $msg_compile = <<'ENDofMSG';
Global symbol "$kaboom" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_compile = $parser->parse_string($msg_compile);
is( scalar(@errors_compile),          1,                                                        'msg_compile results' );
is( $errors_compile[0]->message,      'Global symbol "$kaboom" requires explicit package name', 'msg_compile message' );
is( $errors_compile[0]->file_msgpath, 'error.pl',                                               'msg_compile file' );
is( $errors_compile[0]->line,         8,                                                        'msg_compile line' );


# use strict;
# use warnings;
#
# my $empty;
# my $length = length($empty);
#
# my $zero = 0;
# my $result = 5 / 0;

my $msg_runtime = <<'ENDofMSG';
Use of uninitialized value $empty in length at error.pl line 5.
Illegal division by zero at error.pl line 8.
ENDofMSG

my @errors_runtime = $parser->parse_string($msg_runtime);
is( scalar(@errors_runtime),          2,                                             'msg_runtime results' );
is( $errors_runtime[0]->message,      'Use of uninitialized value $empty in length', 'msg_runtime 1 message' );
is( $errors_runtime[0]->file_msgpath, 'error.pl',                                    'msg_runtime 1 file' );
is( $errors_runtime[0]->line,         5,                                             'msg_runtime 1 line' );
is( $errors_runtime[1]->message,      'Illegal division by zero',                    'msg_runtime 2 message' );
is( $errors_runtime[1]->file_msgpath, 'error.pl',                                    'msg_runtime 2 file' );
is( $errors_runtime[1]->line,         8,                                             'msg_runtime 2 line' );

# use strict;
# use warnings;
#
# my $string = 'tada';
# kaboom
#
# my $length = 5;

my $msg_near1 = <<'ENDofMSG';
syntax error at error.pl line 7, near "kaboom

my "
Global symbol "$length" requires explicit package name at error.pl line 7.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_near1 = $parser->parse_string($msg_near1);
is( scalar(@errors_near1),          2,              'msg_near results' );
is( $errors_near1[0]->message,      'syntax error', 'msg_near 1 message' );
is( $errors_near1[0]->file_msgpath, 'error.pl',     'msg_near 1 file' );
is( $errors_near1[0]->line,         7,              'msg_near 1 line' );
is( $errors_near1[0]->near, 'kaboom

my ', 'msg_near 1 near'
);
is( $errors_near1[1]->message,      'Global symbol "$length" requires explicit package name', 'msg_near 2 message' );
is( $errors_near1[1]->file_msgpath, 'error.pl',                                               'msg_near 2 file' );
is( $errors_near1[1]->line,         7,                                                        'msg_near 2 line' );

# package;
#
my $msg_near2 = <<'ENDofMSG';
syntax error at -e line 1, near "package;"
-e had compilation errors.
ENDofMSG

my @errors_near2 = $parser->parse_string($msg_near2);
is( scalar(@errors_near2),          1,              'msg_near 2 results' );
is( $errors_near2[0]->message,      'syntax error', 'msg_near 2 message' );
is( $errors_near2[0]->file_msgpath, '-e',           'msg_near 2 file' );
is( $errors_near2[0]->line,         1,              'msg_near 2 line' );
is( $errors_near2[0]->near,         'package;' );

#use strict;
#use warnings;
#
#if (1) { if (2)

my $msg_at = <<'ENDofMSG';
syntax error at error.pl line 4, at EOF
Missing right curly or square bracket at error.pl line 4, at end of line
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_at = $parser->parse_string($msg_at);
is( scalar(@errors_at),          2,                                       'msg_at results' );
is( $errors_at[0]->message,      'syntax error',                          'msg_at 1 message' );
is( $errors_at[0]->file_msgpath, 'error.pl',                              'msg_at 1 file' );
is( $errors_at[0]->line,         4,                                       'msg_at 1 line' );
is( $errors_at[0]->at,           'EOF',                                   'msg_at 1 at' );
is( $errors_at[1]->message,      'Missing right curly or square bracket', 'msg_at 2 message' );
is( $errors_at[1]->file_msgpath, 'error.pl',                              'msg_at 2 file' );
is( $errors_at[1]->line,         4,                                       'msg_at 2 line' );
is( $errors_at[1]->at,           'end of line',                           'msg_at 2 at' );

# use strict;
# use warnings;
#
# eval 'sub test {print}';
# test();

my $msg_eval = <<'ENDofMSG';
Use of uninitialized value $_ in print at (eval 1) line 1.
ENDofMSG

my @errors_eval = $parser->parse_string($msg_eval);
is( scalar(@errors_eval),          1,                                        'msg_eval results' );
is( $errors_eval[0]->message,      'Use of uninitialized value $_ in print', 'msg_eval 1 message' );
is( $errors_eval[0]->file_msgpath, '(eval 1)',                               'msg_eval 1 file' );
is( $errors_eval[0]->file,         'eval',                                   'msg_eval 1 eval' );
is( $errors_eval[0]->line,         1,                                        'msg_eval 1 line' );

