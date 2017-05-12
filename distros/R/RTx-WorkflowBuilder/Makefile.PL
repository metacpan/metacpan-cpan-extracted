use inc::Module::Install;

RTx('RTx-WorkflowBuilder');

name            ('RTx-WorkflowBuilder');
abstract        ('Helpers for building workflow for queues in RT');
author          ('Chia-liang Kao <clkao@bestpractical.com>');
version_from    ('lib/RTx//WorkflowBuilder.pm');
license         ('GPL version 2');

requires        ('Class::Accessor::Fast');

&WriteAll;
