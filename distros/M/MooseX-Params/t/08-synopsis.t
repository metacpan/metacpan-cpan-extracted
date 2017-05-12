use strict;
use warnings;

use Test::Most;
use IO::String;

{
    package TestSynopsisModule;

    use MooseX::Params;
    use Moose::Util::TypeConstraints;

    sub add :Args(Int first, Int second) {
        return $_{first} + $_{second};
    }

    sub add2 :Args(Int first, Int second) {
        my ($first, $second) = @_;
        return $first + $second;
    }

    subtype 'HexNum',
        as 'Str',
        where { /[a-f0-9]/i };

    coerce 'Int',
        from 'HexNum',
        via { hex $_ };

    sub add3 :Args(&Int first, &Int second) {
        return $_{first} + $_{second};
    }

    sub sum :Args(ArrayRef *values) {
        my $sum = 0;

        my @values = @{$_{values}};

        foreach my $value (@values)
        {
          $sum += $value;
        }

        return $sum;
    }

    sub search :Args(text, fh, all?) {
        my $cnt = 0;

        while (my $line = $_{fh}->getline)
        {
            if ( index($line, $_{text}) > -1 )
            {
                return 1 if not $_{all};
                $cnt++;
            }
        }

        return $cnt;
    }

    sub foo :Args(a, :b)
    {
        return $_{a} + $_{b} * 2;
    }

    sub trim :Args(Str string)
    {
        my $string = $_{string};
        $string =~ s/^\s*//;
        $string =~ s/\s*$//;
        return $string;
    }

    sub find_clothes :Args(:size = 'medium', :color = 'white') {
        return "size: $_{size}, color: $_{color}";
    }

    sub find_some_clothes :Args(
        :size   = _build_param_size,
        :color  = _build_param_color,
        :height = 170 )
    {
        return "size: $_{size}, color: $_{color}";
    }

    sub _build_param_color
    {
        return 'white';
    }

    sub _build_param_size
    {
        return $_{height} > 200 ? 'large' : 'medium';
    }

    sub process_template
        :Args(input, output, param)
        :BuildArgs(_buildargs_process_template)
    {
        return "input: $_{input}, output: $_{output}, param: $_{param}";
    }

    sub _buildargs_process_template
    {
        if (@_ == 2) {
            my ($input, $param) = @_;
            my $output = $input;
            substr($output, -4, 4, "html");
            return $input, $output, $param;
        } else {
            return @_;
        }
    }

    sub process_person
        :Args(:first_name!, :last_name!, :country!, :ssn?)
        :CheckArgs
    { return }

    sub _checkargs_process_person
    {
        if ( $_{country} eq 'USA' )
        {
            die 'All US residents must have an SSN' unless $_{ssn};
        }
    }
}

{
    package TestSynopsisClass;

    use Moose;
    use MooseX::Params;

    has 'password' => (
        is  => 'rw',
        isa => 'Str',
    );

    sub login :Args(self: Str pw)
    {
        return 0 if $_{pw} ne $_{self}->password;
        return 1;
    }
}

is      ( TestSynopsisModule::add(2,3),         5,       'basic' );
is      ( TestSynopsisModule::add2(2,3),        5,       'without %_' );
is      ( TestSynopsisModule::add3(2,3),        5,       'without coercion' );
is      ( TestSynopsisModule::add3('A','B'),    21,      'with coercion' );
is      ( TestSynopsisModule::sum(2, 3, 4, 5),  14,      'slurpy arguments' );
is      ( TestSynopsisModule::foo( 3, b => 2 ), 7,       'name arguments' );
is      ( TestSynopsisModule::trim(' hello '),  'hello', 'mutable' );

is      ( TestSynopsisModule::search('e', IO::String->new("Peter\nGeorge\nJohn")),    1, 'without optional parameter' );
is      ( TestSynopsisModule::search('e', IO::String->new("Peter\nGeorge\nJohn"), 1), 2, 'with optional parameter' );

dies_ok { TestSynopsisModule::add(2)       } 'fewer arguments';
dies_ok { TestSynopsisModule::foo(4, 9)    } 'named arguments passed as positional';
dies_ok { TestSynopsisModule::foo(2)       } 'no named argument';
dies_ok { TestSynopsisModule::foo(2, 3, 4) } 'misnamed argument';

is ( TestSynopsisModule::find_clothes,
    'size: medium, color: white', 'with defaults' );
is ( TestSynopsisModule::find_clothes( size => 'large', color => 'green'),
    'size: large, color: green', 'without defaults' );
is ( TestSynopsisModule::find_some_clothes,
    'size: medium, color: white', 'with builders' );
is ( TestSynopsisModule::find_some_clothes( size => 'large', color => 'green'),
    'size: large, color: green', 'without builders' );

is ( TestSynopsisModule::process_template('from.tmpl', 'to.html', 'test'),
    'input: from.tmpl, output: to.html, param: test' , 'without buildargs');
is ( TestSynopsisModule::process_template('index.tmpl', 'test'),
    'input: index.tmpl, output: index.html, param: test' , 'with buildargs');

lives_ok { TestSynopsisModule::process_person(
        first_name => 'Peter',
        last_name  => 'Jackson',
        country    => 'UK',
) } 'checkargs lives';

dies_ok { TestSynopsisModule::process_person(
        first_name => 'Peter',
        last_name  => 'Jackson',
        country    => 'USA',
) } 'checkargs dies';

my $user = TestSynopsisClass->new( password => '123' );
ok ($user->login('123'), 'object 1');
ok (!$user->login('456'), 'object 2');

done_testing;
