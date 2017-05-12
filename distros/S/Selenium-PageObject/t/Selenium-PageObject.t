use strict;
use warnings;

use Test::More 'tests' => 60;
use Test::Fatal;
use Test::Deep;

use Selenium::Remote::Driver;
use WWW::Selenium;
use Selenium::PageObject;

use File::Basename;
use Cwd qw(abs_path);

like( exception {Selenium::PageObject->new()} , qr/Driver must be an instance/ , "Must pass driver");
like( exception {Selenium::PageObject->new('whee')}, qr/Driver must be an instance/, "Must pass W::S or S::R::D object");

note "Please set the SELENIUM_SERVER_ADDR, SELENIUM_SERVER_PORT and SELENIUM_BROWSER_NAME environment variables to run the remaining tests.";
my $host = $ENV{'SELENIUM_SERVER_ADDR'} // undef;
my $browser_name = $ENV{'SELENIUM_BROWSER_NAME'} // undef;
my $port = $ENV{'SELENIUM_SERVER_PORT'} // undef;

SKIP : {
    skip("No SELENIUM_SERVER_ADDR, SELENIUM_SERVER_PORT and SELENIUM_BROWSER_NAME provided",58) if !$host && !$browser_name && !$port;
    my $webd = Selenium::Remote::Driver->new('remote_server_addr' => $host,'browser_name'=>$browser_name,'port' => $port);

    my $dir = dirname(abs_path($0));
    my $remote_fname = dirname($webd->upload_file( "$dir/test.html" ));

    my $pod = Selenium::PageObject->new($webd,"file://$remote_fname$dir/test.html");
    isa_ok($pod,"Selenium::PageObject");

    my $element = $pod->getElement('paragraph1','id');
    isa_ok($element,"Selenium::Element");
    is($element->get_tag_name,"p","Can get tag name using WebDriver");
    ok(!$element->is_form,"Can get if element is form using WebDriver");
    ok(!$element->get_type(),"Cannot get type of non-input");
    ok(!$element->is_textinput,"Element correctly reported as not textinput");
    ok(!$element->is_fileinput,"Element correctly reported as not fileinput");
    ok(!$element->is_radio,"Element correctly reported as not radio");
    ok(!$element->is_select,"Element correctly reported as not select");
    ok(!$element->is_option,"Element correctly reported as not option");
    ok(!$element->is_checkbox,"Element correctly reported as not cb");
    ok(!$element->has_option('someOption'),"Cannot get options for non-select");
    is($element->get,'BIX NOOD',"get() on non-inputs returns innerText");
    like(exception {$element->set('whee')},qr/non-input/,"Cannot set non-input");

#Get the form element
    $element = $pod->getElement('testForm','id');
    isa_ok($element,"Selenium::Element");
    is($element->get_tag_name,"form","Can get tag name using WebDriver");
    ok($element->is_form,"Can get if element is form using WebDriver");
    ok(!$element->get_type(),"Cannot get type of non-input");
    ok(!$element->is_textinput,"Element correctly reported as not textinput");
    ok(!$element->is_fileinput,"Element correctly reported as not fileinput");
    ok(!$element->is_radio,"Element correctly reported as not radio");
    ok(!$element->is_select,"Element correctly reported as not select");
    ok(!$element->is_option,"Element correctly reported as not option");
    ok(!$element->is_checkbox,"Element correctly reported as not cb");
    ok(!$element->has_option('someOption'),"Cannot get options for non-select");

    my $value;

#Get all the inputs for the form
    my @inputs = $pod->getElements('#testForm input, #testForm textarea, #testForm select, #testForm select option','css');
    foreach my $input (@inputs) {
        subtest 'Element state is as expected' => sub {
            isa_ok($input,"Selenium::Element");
            ok($input->get_tag_name,"Can get tag name using WebDriver");
            ok(!$input->is_form,"Can get if element is not form using WebDriver");
            ok(!$input->get_type(),"Cannot get type of non-input") if !$input->is_input;
            ok($input->get_type(),"Can get type of input") if $input->is_input;
            ok($input->is_textinput,"Element correctly reported as not textinput") if $input->id eq 'textinput1';
            ok($input->is_fileinput,"Element correctly reported as not fileinput") if $input->id eq 'file1';
            ok($input->is_radio,"Element correctly reported as not radio") if grep {$_ eq $input->id} qw('radio1 radio2');
            ok($input->is_select,"Element correctly reported as not select") if $input->id eq 'select1';
            ok($input->is_option,"Element correctly reported as not option") if grep {$_ eq $input->name} qw('option1 option2 option3');
            ok($input->is_checkbox,"Element correctly reported as not cb") if $input->id eq 'cb4';
            ok(!$input->has_option('someOption'),"Cannot get options for non-select") if $input->get_tag_name ne 'select';
            ok($input->has_option('option2'),"Can get options for select") if $input->get_tag_name eq 'select' && !$input->is_multiselect;
            ok($input->has_option('option5'),"Can get options for multi-select")if $input->is_multiselect;
            ok($input->is_hiddeninput,"Can get whether input is hidden") if $input->id eq 'urgent';
        };
        subtest 'Getters/Setters work as desired' => sub {
            #Test getters/setters
            $value = $input->get;
            is($value,"option1","Get returns current selection for single select") if $input->is_select && !$input->is_multiselect;
            cmp_deeply($value,['option4','option6'],"Get returns current selections as ARRAY for multi select") if $input->is_multiselect;
            ok($value == 0,"Get returns bool for checkbox") if $input->is_checkbox;
            ok($value == 0,"Get returns bool for radio button") if $input->is_radio;
            like($value,qr/JUKEBOX HERO|guitar|foreigner/,"Get returns text for text inputs") if $input->is_textinput;
            is($value,'Is it obvious I was listening to Foreigner when I wrote this?',"Can get string value of hidden inputs") if $input->is_hiddeninput;
            ok(!!$value == 0 || !!$value == 1, "Can get value of option") if $input->is_option;
            ok($value == '', "Can get value of file input") if $input->is_fileinput;

            if ($input->is_select && !$input->is_multiselect) {
                $input->set('option2');
                is($input->get,'option2',"Set single select to specified option succeeds");
            }
            if ($input->is_multiselect) {
                $input->set(['option5']);
                cmp_deeply($input->get,['option5'],"Can set multi-select with ARRAYREF");
            }
            if ($input->is_checkbox || $input->is_radio) {
                $input->set(1);
                ok($input->get == 1, "Can set radio/checkboxes");
            }
            if ($input->is_fileinput) {
                $input->set("$remote_fname$dir/test.html"); #upload ourself, whee
                is($input->get,"test.html","Can set file fields with string");
            }
            if ($input->is_textinput || $input->is_hiddeninput) {
                $input->set("whee");
                is($input->get,'whee',"Can set text/hidden fields with string");
            }
            if ($input->is_option) {
                $input->set(1);
                ok($input->get == 1,"Can set option on");
                $input->set(0);
                ok($input->get == 0,"Can set option off in multi-select") if grep {$input->name eq $_} qw(option5 option6 option7);
                ok($input->set(1,sub {my $self=shift; return $self->get;}) == 1,"Verify callbacks work as expected for set");
            }
        };
    }

    ok($element->submit(),"Can submit a form");


#WWW::Selenium Tests.
    my $sel  = WWW::Selenium->new('host' => $host, 'browser' => "*$browser_name",'browser_url' => "http://nic.com",'port' => $port); #beats me why it whines if you don't have some page to go to???
    $sel->start;
    my $pows = Selenium::PageObject->new($sel,"file://$remote_fname$dir/test.html");

    isa_ok($pod,"Selenium::PageObject");

    $element = $pod->getElement('paragraph1','id');
    isa_ok($element,"Selenium::Element");
    is($element->get_tag_name,"p","Can get tag name using WebDriver");
    ok(!$element->is_form,"Can get if element is form using WebDriver");
    ok(!$element->get_type(),"Cannot get type of non-input");
    ok(!$element->is_textinput,"Element correctly reported as not textinput");
    ok(!$element->is_fileinput,"Element correctly reported as not fileinput");
    ok(!$element->is_radio,"Element correctly reported as not radio");
    ok(!$element->is_select,"Element correctly reported as not select");
    ok(!$element->is_option,"Element correctly reported as not option");
    ok(!$element->is_checkbox,"Element correctly reported as not cb");
    ok(!$element->has_option('someOption'),"Cannot get options for non-select");
    is($element->get,'BIX NOOD',"get() on non-inputs returns innerText");
    like(exception {$element->set('whee')},qr/non-input/,"Cannot set non-input");

#Get the form element
    $element = $pod->getElement('testForm','id');
    isa_ok($element,"Selenium::Element");
    is($element->get_tag_name,"form","Can get tag name using WebDriver");
    ok($element->is_form,"Can get if element is form using WebDriver");
    ok(!$element->get_type(),"Cannot get type of non-input");
    ok(!$element->is_textinput,"Element correctly reported as not textinput");
    ok(!$element->is_fileinput,"Element correctly reported as not fileinput");
    ok(!$element->is_radio,"Element correctly reported as not radio");
    ok(!$element->is_select,"Element correctly reported as not select");
    ok(!$element->is_option,"Element correctly reported as not option");
    ok(!$element->is_checkbox,"Element correctly reported as not cb");
    ok(!$element->has_option('someOption'),"Cannot get options for non-select");

    $sel->stop();
    #Gotta keep our tmpfile there
    $webd->quit();

}

0;
