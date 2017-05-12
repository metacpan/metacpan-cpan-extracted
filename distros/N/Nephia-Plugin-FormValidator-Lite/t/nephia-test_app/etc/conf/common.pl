### common config
use File::Spec;
use File::Basename qw/dirname/;
+{
    appname => 'MyApp',
    view => {
        path => [File::Spec->catdir(dirname(__FILE__), '..', '..', 'view')],
    },
    'Plugin::FormValidator::Lite' => {
        function_message => 'en',
        constants => [qw/Email/]
    }
};
