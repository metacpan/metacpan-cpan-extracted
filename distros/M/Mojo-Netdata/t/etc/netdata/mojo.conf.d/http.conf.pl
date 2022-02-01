{
  collector    => 'Mojo::Netdata::Collector::HTTP',
  jobs         => ['https://example.com'],
  update_every => 30,
}
