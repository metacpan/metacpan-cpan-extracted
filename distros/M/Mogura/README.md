# Mogura

Inspect a Linux host or an attached ext4 or XFS disk with Syft and Grype. Both the server and scanner require Linux on x86_64 or aarch64 and a 64-bit build of Perl 5.34 or later.

Install the CPAN release and start the server as your regular user.

```sh
cpanm Mogura
mogura server
```

Open [the web interface](http://127.0.0.1:8080), [configure and start a scanner](docs/operations.md#install-and-start-the-scanner), and select a disk under its scanner name. Open History to search results, edit tags and notes, or download the original files.

[Build and test](CONTRIBUTING.md) · [Apache-2.0](LICENSE)
