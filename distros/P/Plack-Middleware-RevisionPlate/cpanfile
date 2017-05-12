requires 'perl', '5.010';
requires 'Plack::Middleware';
requires 'Plack::Response';
requires 'File::Slurp';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Plack::Test';
    requires 'File::Temp';
    requires 'HTTP::Request::Common';
};

on 'develop' => sub {
    requires 'Software::License::MIT';
};