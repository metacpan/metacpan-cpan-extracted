package Pegex::Crontab;
our $VERSION = '0.23';

use Pegex::Base;
extends 'Pegex::Module';

use Pegex::Parser;
use Pegex::Crontab::Grammar;
use Pegex::Crontab::AST;

has parser_class => 'Pegex::Parser';
has grammar_class => 'Pegex::Crontab::Grammar';
has receiver_class => 'Pegex::Crontab::AST';

1;
