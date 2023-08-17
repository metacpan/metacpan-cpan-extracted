
requires 'perl' => '5.14.0';

requires 'Feature::Compat::Try';
requires 'IO::Async::Handle';
requires 'IO::Async::Loop';
requires 'IO::Async::Timer::Periodic';
requires 'Log::Any';
requires 'Sys::Virt';
requires 'Sys::Virt::Event';

feature 'examples' => sub {
    requires 'Future::AsyncAwait';
    requires 'Future::Queue';
};

on develop => sub {
    requires 'Dist::Zilla';
};
