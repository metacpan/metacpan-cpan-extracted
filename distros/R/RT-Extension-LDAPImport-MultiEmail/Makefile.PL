use inc::Module::Install;

RTx 'RT-Extension-LDAPImport-MultiEmail';

requires_rt_plugin "RT::Extension::LDAPImport";
requires_rt_plugin "RT::Extension::MergeUsers";

require File::Basename;
substitute(
    {
        RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ),
    },
    { sufix => '.in' },
    q(t/user-import.t),
);

sign;
WriteAll;
