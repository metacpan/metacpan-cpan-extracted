# Mojo::WebService::LastFM

A Non-Blocking interface to the Last.FM API. Currently only supports the "recenttracks" endpoint, allowing you to query what a user is currently and was recently listening to.

It uses Mojo::UserAgent to make the calls and supports both callbacks and promises (with Mojo::Promise).

I am currently working on getting it ready for CPAN, where you'll be able to install it like any other Perl module. For now you'll need to check out this repo, install the dependencies, and then manually merge it with your perl5 lib directory.

## INSTALL

### Linux / MacOS

```bash
# Clone the repo
git clone https://github.com/vsTerminus/Mojo-WebService-LastFM.git
cd Mojo-WebService-LastFM

# Install dependencies
cpanm --installdeps .

# Manually install to ~/perl5/lib/perl5/
mkdir -p ~/perl5/lib/perl5/Mojo/WebService
ln -s $PWD/lib/Mojo/WebService/Last.fm ~/perl5/lib/perl5/Mojo/WebService/LastFM.pm
```

If your perl5 lib dir is somewhere else, adjust the last two commands accordingly.
