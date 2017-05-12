requires "Any::URI::Escape" => "0";
requires "Carp" => "0";
requires "JSON" => "0";
requires "Moo" => "0";
requires "Scalar::Util" => "0";
requires "Search::Elasticsearch" => "1.10";
requires "Sub::Exporter" => "0";
requires "constant" => "0";
requires "namespace::clean" => "0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "JSON::XS" => "0";
recommends "URI::Escape::XS" => "0";

on 'build' => sub {
  requires "Test::More" => "0.98";
};

on 'test' => sub {
  requires "ElasticSearch::SearchBuilder" => "0";
  requires "Test::Differences" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0.98";
  requires "lib" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
};
