package Psonpath;

=pod

=head1 NAME

psonpath: a CLI that parses JSON data with JSONPath

=head1 DESCRIPTION

C<psonpath> is a very simple program, basically a CLI to the L<JSON::Path>
module.

It uses this module to parse JSON data passed to the program C<STDIN>, applies
the given JSONPath expression and if the result is valid, print it in a nice
formated way to C<STDOUT>, thanks to the L<Data::Printer> module.

Here is an example:

  $ somefile_json_file=~/aws/venv/lib/python3.7/site-packages/awscli-1.16.201.dist-info/metadata.json
  $ cat ${somefile_json_file}
  {"license": "Apache License 2.0", "name": "awscli", "metadata_version": "2.0", "generator": "bdist_wheel (0.24.0)", "summary": "Universal Command Line Environment for AWS.", "run_requires": [{"environment": "python_version!=\"2.6\"", "requires": ["PyYAML>=3.10,<=5.1"]}, {"requires": ["botocore==1.12.191", "colorama>=0.2.5,<=0.3.9", "docutils>=0.10", "rsa>=3.1.2,<=3.5.0", "s3transfer>=0.2.0,<0.3.0"]}, {"environment": "python_version==\"2.6\"", "requires": ["PyYAML>=3.10,<=3.13", "argparse>=1.1"]}], "version": "1.16.201", "extensions": {"python.details": {"project_urls": {"Home": "http://aws.amazon.com/cli/"}, "document_names": {"description": "DESCRIPTION.rst"}, "contacts": [{"role": "author", "name": "Amazon Web Services"}]}}, "classifiers": ["Development Status :: 5 - Production/Stable", "Intended Audience :: Developers", "Intended Audience :: System Administrators", "Natural Language :: English", "License :: OSI Approved :: Apache Software License", "Programming Language :: Python", "Programming Language :: Python :: 2", "Programming Language :: Python :: 2.6", "Programming Language :: Python :: 2.7", "Programming Language :: Python :: 3", "Programming Language :: Python :: 3.3", "Programming Language :: Python :: 3.4", "Programming Language :: Python :: 3.5", "Programming Language :: Python :: 3.6", "Programming Language :: Python :: 3.7"], "extras": []}
  $ cat ${somefile_json_file} | psonpath -exp '$..run_requires.[1]'
  {
      requires   [
          [0] "botocore==1.12.191",
          [1] "colorama>=0.2.5,<=0.3.9",
          [2] "docutils>=0.10",
          [3] "rsa>=3.1.2,<=3.5.0",
          [4] "s3transfer>=0.2.0,<0.3.0"
      ]
  }

If the result of the applied JSONPath expression is not valid, it finished with
and error message and exit code different from zero.

=head1 SEE ALSO

=over

=item *

L<App::PipeFilter|https://metacpan.org/pod/App::PipeFilter> has also a CLI to
apply a JSONPath to JSON data, but with slight different objectives.

=item *

L<JSON::Path|https://metacpan.org/pod/JSON::Path> is the module that makes
C<psonpath> program possible.

=item *

L<JSONPath - XPath for JSON|https://goessner.net/articles/JsonPath/> is an
article about JSONPath. Useful to start learning how to use it.

=item *

L<Data::Printer|https://metacpan.org/pod/Data::Printer> provides the nice,
colored and formatted output to the JSONPath expression.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>.

This file is part of psonpath project.

psonpath is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

psonpath is distributed in the hope that it will be useful, but
B<WITHOUT ANY WARRANTY>; without even the implied warranty of
B<MERCHANTABILITY> or B<FITNESS FOR A PARTICULAR PURPOSE>. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
psonpath. If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
