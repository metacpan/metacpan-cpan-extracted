#!/usr/bin/perl
use strict;
use warnings;

use URI::file;

use Test::More;
plan tests => 33;

use_ok 'Mozilla::Mechanize';

my $url = URI::file->new_abs( "t/html/formbasics.html" )->as_string;

isa_ok my $moz = Mozilla::Mechanize->new(quiet => 1, visible => 0), "Mozilla::Mechanize";
isa_ok $moz->agent, "Mozilla::Mechanize::Browser";

ok $moz->get( $url ), "get($url)";

is $moz->title, "Test-forms Page", "->title method";
is $moz->ct, "text/html", "->ct method";
ok $moz->is_html, "content is html";

my @forms = $moz->forms;
is scalar(@forms), 2, "Form count";

{
    my $form_nb = $moz->form_number(2);
    is $form_nb->name, 'form2', "Form name found";

    my( $value ) = $moz->field( query => 'Modified' );
    is $form_nb->value( "query" ), 'Modified',
       "Form field eq browser field";
    is $moz->value( 'query' ), $value,
       "value(query) method returns '$value'";

    my $form_nm = $moz->form_name( 'form2' );
    is $form_nb, $form_nm, "form-by-name eq form-by-number";

    foreach my $field (qw( dummy2 query )) {
        ok defined $form_nb->find_input( $field ), "Fields exist";
    }

    # This used to return just 'formbasics.html',
    # but in Firefox it's returning
    # 'file:///full/path/Mozilla-Mechanize/t/html/formbasics.html'
    # so I just match the filename
    my $furi = 'formbasics.html';
    like $form_nb->action, qr{$furi$}, "action( $furi )";


    is lc($form_nb->method), 'get', "method=GET";
    is $form_nb->enctype, 'application/x-www-form-urlencoded', "enctype()";
    my $fname = $form_nb->attr( 'name' );
    is $fname, 'form2', "attr( 'name' ) eq $fname";
    is $form_nb->attr( 'unknown' ), undef, "unknown attribute";
    is $form_nb->find_input( 'unknown' ), undef, "unknown input control";
    my $submit = $form_nb->find_input( undef, 'submit' );
    is $submit->value, 'Submit', "Submit-button";

    my @flags = $form_nb->find_input( 'flags' );
    is scalar @flags, 2, "number of checkboxes";

    my $flag2 = $form_nb->find_input( 'flags', undef, 2);
    is $flag2->value, 2, "second value";
    my( $flag1 ) = $form_nb->find_input( 'flags', undef, 1);
    is $flag1->value, 1, "first value";
    {
        isa_ok $moz->form_number( 2 ), 'Mozilla::Mechanize::Form';
        ok $moz->tick( flags => 1 ), "tick( 1 )";
        ok $moz->tick( flags => 2 ), "tick( 2 )";
        my @vals = $moz->value( 'flags' );
        is_deeply \@vals, [1, 2], "values( flags )";
    }
    ok !$moz->form_name( 'doesnotexist' ),
       "Cannot select unknown form";
}

{
    my $form_nb = $moz->form_number( 1 );
    ok $form_nb, "Form number found";

    ok !$moz->form_name( 'doesnotexist' ),
       "Cannot select unknown form";
}

my $prev_uri = $moz->uri;
ok $moz->form_name( 'form2' ), "Selected the form";
$moz->untick( flags => $_ ) for ( 1..2 );
$moz->submit_form(
    form_name => 'form2',
    fields    => {
        dummy2 => 'filled',
        query  => 'text',
    }
);
is $moz->uri, "$prev_uri?dummy2=filled&query=text",
   "Form submitted";

$moz->close();
