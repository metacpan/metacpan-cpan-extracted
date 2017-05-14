# Net::HTTP::Knork #

This is a [SPORE](https://github.com/SPORE/specifications/blob/master/spore_description.pod) client implementation.

### Install from CPAN ###

* if not done yet, install [cpanm](https://metacpan.org/pod/App::cpanminus#INSTALLATION)
* install the module from cpan : `cpanm Net::HTTP::Knork`

### Install from repository ###

* clone this repository : `hg clone ssh://hg@bitbucket.org/peroumal1/net-http-knork`
* install the author dependencies : `dzil authordeps | cpanm`
* install the module dependencies : `dzil listdeps | cpanm`
* all set !

### Contribution guidelines ###

#### Reporting an issue ####

* any issue can be reported on the issue tracker of the repository 
* an issue should give some details regarding the error experienced : environment, how to reproduce, workaround (if any)...

#### Submitting a patch ####

* if you find an error or want an improvement on something, you can submit a patch by submitting a merge request 
* a merge request MUST come with tests that prove the correctness of the patch submitted. See also [this](https://metacpan.org/pod/Net::HTTP::Knork#TESTING) or the `t` folder of the repository to have an idea on how to implement tests for Net::HTTP::Knork