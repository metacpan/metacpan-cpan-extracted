use 5.20.0;

use Test::More;
use Test::Synopsis::Expectation;

require_ok('Software::Copyright::Statement');

synopsis_ok('lib/Software/Copyright/Statement.pm');

subtest "just a name" => sub {
    my $statement = Software::Copyright::Statement->new('Marcel <marcel@example.com>');

    is("$statement", 'Marcel <marcel@example.com>', "check simplified statement");
    is($statement->name, 'Marcel', "check simplified statement name");
    is($statement->email, 'marcel@example.com', "check simplified statement email");
};

subtest "O'name" => sub {
    my $statement = Software::Copyright::Statement->new(q!Tony O'Dell!);

    is($statement->name, "Tony O'Dell", "check simplified statement name");
};

subtest "single statement" => sub {
    my $statement = Software::Copyright::Statement->new('2014,2015-2022 Marcel <marcel@example.com>');

    is("$statement", '2014-2022, Marcel <marcel@example.com>', "check simplified statement");
};

subtest "just a number" => sub {
    my $statement = Software::Copyright::Statement->new('2021');

    is($statement->name, undef, "check statement without name");
    is("$statement", '', "check statement string without name");
};

subtest "combined owners" => sub {
    my $owner_str = "Blaine Bublitz, Eric Schoffstall and other contributors";
    my $str = "2014, 2015, $owner_str";
    my $owner = Software::Copyright::Statement->new($str);

    is("$owner", $str, "check statement string");
    is($owner->name, undef, "check owner name");
    is($owner->record, "Blaine Bublitz, Eric Schoffstall and other contributors", "check owner record");
};

subtest "combined owners and email" => sub {
    my $owner_str = 'Blaine Bublitz <blaine.bublitz@gmail.com>,'
        . ' Eric Schoffstall <yo@contra.io> and other contributors';
    my $str = '2013-2018, '.$owner_str;
    my $owner = Software::Copyright::Statement->new($str);

    is("$owner", $str, "check statement string");
    is($owner->name, undef, "check owner name");
    is($owner->record, $owner_str, "check owner record");
    is($owner->email, undef, "check owner email");
};

subtest "compare statements" => sub {
    my $one   = Software::Copyright::Statement->new('2022 Thierry');
    my $other = Software::Copyright::Statement->new('2014,2015-2022 Marcel <marcel@example.com>');

    is($one cmp $one, 0, "check cmp equal");
    is($one cmp $other, 1, "check cmp equal");
    is($other cmp $one, -1, "check cmp equal");
};

subtest "merge record" => sub {
    my $statement = Software::Copyright::Statement->new('2014,2015-2020 Marcel');

    $statement->merge(Software::Copyright::Statement->new('2004-06 Marcel'));
    is("$statement", '2004-2006, 2014-2020, Marcel', "check simplified statement");

    $statement->merge(Software::Copyright::Statement->new('2007-08 Marcel'));
    is("$statement", '2004-2008, 2014-2020, Marcel', "check statement after year merge");

    $statement->merge(Software::Copyright::Statement->new('2021, Marcel'));
    is("$statement", '2004-2008, 2014-2021, Marcel', "check statement after 2021 year merge");

    # add email
    $statement->merge(Software::Copyright::Statement->new('Marcel <marcel@bad.com>'));
    is("$statement", '2004-2008, 2014-2021, Marcel <marcel@bad.com>', "merge bad email address");

    # fix email
    $statement->merge(Software::Copyright::Statement->new('2022, Marcel <marcel@example.com>'));
    is("$statement", '2004-2008, 2014-2022, Marcel <marcel@example.com>', "fix email");

};

done_testing;

