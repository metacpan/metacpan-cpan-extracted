package TaskPipe::Template_Config_Project_SP500;

use Moose;
extends 'TaskPipe::Template_Config_Project';


has adjustments => (is => 'ro', isa => 'HashRef', default => sub{{
    'TaskPipe::Task_Scrape::Settings' => {
        ua_handler_module => 'TaskPipe::UserAgentManager::UserAgentHandler_PhantomJS'
    }
}});


1;
        
