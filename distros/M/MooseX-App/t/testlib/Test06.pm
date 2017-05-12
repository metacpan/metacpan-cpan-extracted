package Test06;

use MooseX::App qw(Config);
app_fuzzy(1);
#app_namespace();
app_command_name {
    my @parts = split( /[_\s]+|\b|(?<![A-Z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/, shift );
    return lc(join('-',@parts));
};
app_command_register 'command-c' => 'Test03::ExtraCommand';

app_permute 1;

option 'some_option' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Enable this to do fancy stuff],
);



1;