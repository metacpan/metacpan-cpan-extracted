# date
DATE=`date`;

# Create Git files/stuff
GIT_FILES=".gitignore DEVELOPER.md ERROR.md SETUP.md CHANGELOG CONTRIBUTING LICENSE README.md";

SETTINGS_FILE=./.settings;

# app name
APPNAME="";
if [ "$1" = '' ]; then
	APPNAME='AppName';
	echo "USAGE: ";
	echo "$0 AppName";
	echo "";
	exit 0;
else
	APPNAME="$1";
	# add $1 to file
	echo "APP_NAME=$1" > $SETTINGS_FILE;
	# append lowercase of $1 to file
	LOWERCASE=$(echo "$1" | tr '[:upper:]' '[:lower:]');
	echo "YAML_NAME=$LOWERCASE.yml" >> $SETTINGS_FILE;
	# 
	echo "Showing content of $SETTINGS_FILE";
	`cat $SETTINGS_FILE`;
	echo "";
fi

# DIR
DIR=.;

add_common_git_files () {

	for f in $GIT_FILES;
		do
			if [ -f $f ]; then
				echo "$f already exists";
				#echo "Adding current date to $f";
				#echo "$DATE" >> $f;
			else
				touch $f;
				echo "$DATE" >> $f;
				git add $f;
			fi
		done
}

#
if [ -d ./.git ]; then

	for f in $GIT_FILES;
		do
			if [ -f $f ]; then
				echo "$f already exists";
				#echo "Adding current date to $f";
				#echo "$DATE" >> $f;
			else
				touch $f;
				echo "$DATE" >> $f;
				git add $f;
			fi
		done

else

	echo "Initiating git";
	git init;

	add_common_git_files

	echo "Adding all files in current directory to git";
	git add .;

	echo "first commit";
	git commit -am '000 Init.';

fi

#
if [ -d templates/example ]; then
	mv templates/example templates/home
fi

if [ -f lib/$APPNAME/Controller/Example.pm ]; then
	mv lib/$APPNAME/Controller/Example.pm lib/$APPNAME/Home.pm
fi

if [ -d lib/$APPNAME/Controller ]; then
	rm -rf lib/$APPNAME/Controller
fi

# the following will not cause any problems/errors even if run multiple times
sed -i 's/example/home/' lib/$APPNAME.pm
# delete lines 4 through 9 (range of lines)
sed -i '4,9d' templates/home/welcome.html.ep
#
echo "Home" >> templates/home/welcome.html.ep
#
sed -i 's/Controller::Example/Home/' lib/$APPNAME/Home.pm
sed -i "s/Welcome to the Mojolicious real-time web framework/Welcome to $APPNAME/" lib/$APPNAME/Home.pm
sed -i 's/example/home/' lib/$APPNAME/Home.pm
sed -i 's/Example/Home/' lib/$APPNAME/$APPNAME.pm

#
sed -i 's/Server::/$APPNAME/' lib/$APPNAME/*.pm
sed -i 's/Server::/$APPNAME/' lib/$APPNAME/Schema/Result/*.pm

# do it again only for 1 time 
sed -i 's/$APPNAME/Dockrl92::/' lib/$APPNAME/*.pm
sed -i 's/$APPNAME/Dockrl92::/' lib/$APPNAME/Schema/Result/*.pm

echo "Listing files in current dir.";
ls $DIR;

echo "Get git status";
git status

echo "get git log -1";
git log -1 ;

echo "";
