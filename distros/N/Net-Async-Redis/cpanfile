requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.40';
requires 'Future::AsyncAwait', '>= 0.27';
requires 'Syntax::Keyword::Try', '>= 0.08';
requires 'IO::Async', 0;
requires 'Ryu::Async', '>= 0.006';
requires 'List::Util', '>= 1.29';
requires 'Log::Any', '>= 1.050';
requires 'URI', 0;
requires 'URI::redis', 0;
requires 'Class::Method::Modifiers', 0;
requires 'Math::Random::Secure', 0;

requires 'OpenTracing', '>= 0.003';

on 'test' => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::HexString', 0;
    requires 'Test::Deep', 0;
    requires 'Variable::Disposition', '>= 0.004';
};

on 'develop' => sub {
    requires 'Net::Async::HTTP';
    requires 'Template';
    requires 'HTML::TreeBuilder';
};
