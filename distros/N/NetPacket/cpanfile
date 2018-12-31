requires "Carp" => "0";
requires "Exporter" => "0";
requires "Socket" => "1.87";
requires "constant" => "0";
requires "parent" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Net::Pcap" => "0";
recommends "Net::PcapUtils" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
