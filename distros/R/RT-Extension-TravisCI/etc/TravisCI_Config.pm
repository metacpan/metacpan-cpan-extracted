Set( %TravisCI,
     APIURL => 'https://api.travis-ci.org',
     WebURL  => 'https://travis-ci.org/github',
     APIVersion => '3',
     SlugPrefix => 'bestpractical',
     DefaultProject => 'rt',
     Queues => ['Branch Review'],
);

# You probably need to set an authorization token also
# Set( %TravisCI,
#      AuthToken => '-XXXXXXXX99999999'
# );

1;
