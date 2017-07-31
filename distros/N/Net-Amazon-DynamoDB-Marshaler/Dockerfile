FROM perl:latest

# We'll use the 'app' user
ENV APPUSER=app
RUN adduser --system --shell /bin/false --disabled-password --disabled-login $APPUSER

# Setup work dir
ENV APPDIR=/opt/Net-Amazon-DynamoDB-Marshaler
RUN install -d -o $APPUSER $APPDIR

# Install dependencies

# This needs to be installed to get Dist::Milla installed (broken dependency
# chain somewhere).
RUN cpanm JSON

# Explicitly install these before using cpanfile, because they take awhile and
# we want to cache them.
RUN cpanm Dist::Milla

# Install the rest using cpanfile
ADD cpanfile $APPDIR/
RUN cpanm --installdeps --with-develop $APPDIR

# Setup to use appuser going forward
USER $APPUSER
ENV HOME=/home/$APPUSER
WORKDIR $APPDIR

# Add github known host
RUN mkdir -p -m 700 $HOME/.ssh && touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/known_hosts && echo "|1|PP7G0rKxAVwhmywPPiiZPpqTDW8=|ff8vBJBPaJyg7s7S7y+Bi6ct4P8= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> $HOME/.ssh/known_hosts
