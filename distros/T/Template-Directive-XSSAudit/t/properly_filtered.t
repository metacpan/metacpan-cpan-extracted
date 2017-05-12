use Test::More;

use Template::Directive::XSSAudit;
use Template;
use List::Util qw(sum);

#$Template::Parser::DEBUG = 1;
#$Template::Directive::PRETTY = 1;

my $TT2 = Template->new({
    FACTORY => 'Template::Directive::XSSAudit'
});

my @ERROR;
my @OK;

Template::Directive::XSSAudit->good_filters([ 'html', 'uri' ]);
Template::Directive::XSSAudit->on_error( sub {
    push @ERROR, [ @_ ];
});
Template::Directive::XSSAudit->on_filtered( sub {
    push @OK, [ @_ ];
});

my @tests = (
    {
        count => 3,
        code => sub {
            my $t = "one variable - properly escaped - pipe filter";
    
            my $input = "[% user.email | html %]";
    
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 1, "$t - 1 success" ); 
            is_deeply( $OK[0]->[0], {
               'filtered_by' => [ 'html' ],
               'file_name' => 'input text',
               'file_line' => '1',
               'variable_name' => 'user.email'
            }, "$t - ok hash matches" );
        },
    },
    {
        count => 3,
        code => sub {
            my $t = "one variable - properly escaped - block filter";
    
            my $input = "[% FILTER html %][% user.email %][% END %]";
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 1, "$t - 1 success" ); 
            is_deeply( $OK[0]->[0], {
               'filtered_by' => [ 'html' ],
               'file_name' => 'input text',
               'file_line' => '1',
               'variable_name' => 'user.email'
            }, "$t - ok hash matches" );
        },
    },
    {
        count => 3,
        code => sub {
            my $t = "one variable - properly escaped - filter inline";
    
            my $input = "[% user.email FILTER html %]";
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 1, "$t - 1 success" ); 
            is_deeply( $OK[0]->[0], {
               'filtered_by' => [ 'html' ],
               'file_name' => 'input text',
               'file_line' => '1',
               'variable_name' => 'user.email'
            }, "$t - ok hash matches" );

        },
    },
    {
        count => 2,
        code => sub {
            my $t = "switch / case - case with one literal directive";
    
            my $input = "[% SET a='aee'; SET b='bee'; %][% SWITCH letter; CASE a; '<p></p>'; END; %]";
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 0, "$t - no success -- no filtering needed" ); 
        },
    },
    {
        count => 2,
        code => sub {
            my $t = "switch / case - case with multiple literal directives";
    
            my $input = "[% SET a='aee'; SET b='bee'; %][% SWITCH letter; CASE a; '<p></p>'; '<p>'; END; %]";
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 0, "$t - no success -- no filtering needed" ); 
        },
    },
    {
        count => 3,
        code => sub {
            my $t = "switch / case - case with multiple directives (mixed)";
    
            my $input = "[% SET a='aee'; SET b='bee'; %][% SWITCH letter; CASE a; '<p>a</p>'; CASE b; '<p>' %][% FILTER html; b; END; '</p>'; END; %]";
            @ERROR = @OK = ();
    
            $TT2->process(\$input,{},\my $out) || die $TT2->error();
    
            is( scalar @ERROR, 0, "$t - no errors" );
            is( scalar @OK, 1, "$t - 1 success" ); 
            is_deeply( $OK[0]->[0], {
               'filtered_by' => [ 'html' ],
               'file_name' => 'input text',
               'file_line' => '1',
               'variable_name' => 'b'
            }, "$t - ok hash matches" );
        },
    },
);

plan tests =>  sum map { $_->{count} } @tests;

$_->{code}->() for @tests;

