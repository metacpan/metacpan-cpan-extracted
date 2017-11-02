use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Net::AMQP::RabbitMQ::Batch',
    AUTHOR          => 'Alex Svetkin',
    LICENSE         => 'MIT',
    VERSION_FROM    => 'lib/Net/AMQP/RabbitMQ/Batch.pm',
    ABSTRACT_FROM   => 'lib/Net/AMQP/RabbitMQ/Batch.pm',
    PREREQ_PM       => {
        'Carp'                => 0,
        'Carp::Assert'        => 0,
        'Try::Tiny'           => 0,
        'Time::HiRes'         => 0,
        'Net::AMQP::RabbitMQ' => 0
    },
    TEST_REQUIRES   => {
        'Test::Simple' => 0
    }
)
