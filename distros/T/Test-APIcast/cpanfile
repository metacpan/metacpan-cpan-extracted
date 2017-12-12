requires 'perl', '5.008001';
requires 'Test::Nginx', '>= 0.26';
requires 'JSON', '>= 2';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
  requires 'Minilla';
  requires 'Version::Next';
  requires 'CPAN::Uploader';
  requires 'Software::License::Apache_2_0';
};

