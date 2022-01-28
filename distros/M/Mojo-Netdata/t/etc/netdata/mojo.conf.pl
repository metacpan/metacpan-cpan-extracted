{
  collectors => [
    {
      class        => 'Mojo::Netdata::Collector::HTTP',
      update_every => 30,
      jobs         => {
        'https://example.com' =>
          {method => 'GET', headers => {}, direct_ip => '192.0.2.42', group => 'test',},
      },
    },
  ],
}
