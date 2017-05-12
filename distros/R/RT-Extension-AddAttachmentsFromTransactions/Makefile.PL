use inc::Module::Install;

RTx 'RT-Extension-AddAttachmentsFromTransactions';
repository 'https://github.com/cloos/RT-Extension-AddAttachmentsFromTransactions';

requires 'List::MoreUtils';

requires_rt '4.0.8';
rt_too_new '4.4.0';

no_index package => 'RT::Action::SendEmail';
no_index package => 'RT::Attachment';
no_index package => 'RT::Ticket';

substitute(
    { RT_LIB_PATH => "$RT::LocalPath/lib " . File::Basename::dirname( $INC{'RT.pm'} ) },
    { sufix => '.in' },
    'xt/lib/RT/Extension/AddAttachmentsFromTransactions/Test.pm',
);

sign;
WriteAll;
