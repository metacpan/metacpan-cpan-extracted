use Test::More tests => 85;

BEGIN {
use_ok( 'String::BOM','string_has_bom','fake' );
}

diag( "Testing String::BOM $String::BOM::VERSION" );
ok(defined &string_has_bom, 'imports fine');
ok(!defined &strip_bom_from_string, 'does not import ungiven');
ok(!defined &fake, 'doe not import non existant');

#### string tests ####

ok(string_has_bom("\x00\x00\xfe\xff miscdata") eq 'UTF-32','string_has_bom() UTF-32');
ok(string_has_bom("\xff\xfe\x00\x00 miscdata") eq 'UTF-32','string_has_bom() UTF-32');
ok(string_has_bom("\xfe\xff miscdata") eq 'UTF-16','string_has_bom() UTF-16');
ok(string_has_bom("\xff\xfe miscdata") eq 'UTF-16','string_has_bom() UTF-16');
ok(string_has_bom("\xef\xbb\xbf miscdata") eq 'UTF-8','string_has_bom() UTF-8');

ok(!String::BOM::string_has_bom("miscdata\x00\x00\xfe\xff miscdata"),'!string_has_bom() UTF-32 like');
ok(!String::BOM::string_has_bom("miscdata\xff\xfe\x00\x00 miscdata"),'!string_has_bom() UTF-32 like');
ok(!String::BOM::string_has_bom("miscdata\xfe\xff miscdata"),'!string_has_bom() UTF-16 like');
ok(!String::BOM::string_has_bom("miscdata\xff\xfe miscdata"),'!string_has_bom() UTF-16 like');
ok(!String::BOM::string_has_bom("miscdata\xef\xbb\xbf miscdata"),'!string_has_bom() UTF-8 like');

#### file tests  ####

eval "require File::Slurp;";
SKIP: {
    skip 'Please install File::Slurp', 71 if $@;
    my %files = (
        '.bom_UTF-32.1' => "\x00\x00\xfe\xff miscdata",
        '.bom_UTF-32.2' => "\xff\xfe\x00\x00 miscdata",
        '.bom_UTF-16.1' => "\xfe\xff miscdata",
        '.bom_UTF-16.2' => "\xff\xfe miscdata",
        '.bom_UTF-8.1' => "\xef\xbb\xbf miscdata",
    );
    for my $file (sort keys %files) {
        unlink $file, "$file.none";
        # TODO: peter out if -e either
        File::Slurp::write_file($file,$files{$file});  
        File::Slurp::write_file("$file.none","miscdata$files{$file}");  
        # TODO: pwter out if !-e either
        
        my ($name) = $file =~ m{\.bom\_(UTF-[0-9]+)\.[0-9]+};
        ok(String::BOM::file_has_bom($file) eq $name, "file_has_bom() $file");
        ok(!String::BOM::file_has_bom("$file.none"), "!file_has_bom() $file.none");
        ok(!String::BOM::file_has_bom("$file.open_will_fail"), "!file_has_bom() $file.open_will_fail");
        ok(String::BOM::strip_bom_from_file($file), "strip_bom_from_file() $file");
        ok(String::BOM::strip_bom_from_file("$file.none"), "strip_bom_from_file() $file.none");
        ok(!-e "$file.bak", ".bak file removed when changed");
        ok(!-e "$file.none.bak", "not .bak file to remove when no change");
        ok(!String::BOM::strip_bom_from_file("$file.open_will_fail"), "!strip_bom_from_file() $file.open_will_fail");
        ok(!String::BOM::file_has_bom($file), "!file_has_bom() after strip $file");
        ok(!String::BOM::file_has_bom("$file.none"), "!file_has_bom() (still) after strip $file.none");
        
        File::Slurp::write_file($file,$files{$file});  
        File::Slurp::write_file("$file.none","miscdata$files{$file}");
        ok(String::BOM::strip_bom_from_file($file,1), "strip_bom_from_file() $file");
        ok(String::BOM::strip_bom_from_file("$file.none",1), "strip_bom_from_file() $file.none");
        ok(-e "$file.bak", ".bak file preserved when requested when changed");
        ok(!-e "$file.none.bak", "there is no .bak to preserve when requested when there is no change");
    }
    
    ok(!String::BOM::strip_bom_from_file("asfvavadf") && $!, "strip_bom_from_file() !-e file");
};
