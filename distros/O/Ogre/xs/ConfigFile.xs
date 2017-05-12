MODULE = Ogre     PACKAGE = Ogre::ConfigFile

ConfigFile *
ConfigFile::new()

void
ConfigFile::DESTROY()

## there are three different 'load', only one partially wrapped here for now
void
ConfigFile::load(filename)
    String  filename

void
ConfigFile::clear()


## Note: this replaces ConfigFile::getSectionIterator().
## Instead of an interator, it returns an array ref.
## (The iterator is over a std::map, which is like a hash,
## but I wasn unsure whether the order of the keys matter,
## so I used an array.)
## Each element of this aref is a hash ref with two keys: name and settings.
## name is the section name, a simple string. settings is
## an array ref (which replaces an iterator over the multimap
## SectionIterator.getNext()). Each element of settings
## is in turn an array ref containing two values (replacing i->first
## and i->second on the multimap iterator).
## Sorry if this seems really complicated, but I was unsure how to
## handle C++ iterators, multimaps, etc.. An example:
## $cf = Ogre::ConfigFile->new(); $cf->load('resources.cfg');
## $secs = $cf->getSections();
## for $sec (@$secs) {
##     $secname = $sec->{name};
##     $settings = $sec->{settings};
##     for $setting (@$settings) {
##         ($typename, $archname) = @$setting;
##         ....
##     }
## }
SV *
ConfigFile::getSections()
  INIT:
    // this is derived from defineResources in OGRE's BasicTutorial6
    // and example 6 in perlxstut
    AV * sections;
    ConfigFile::SettingsMultiMap *settingmmap;
    ConfigFile::SettingsMultiMap::iterator i;
    String secName, typeName, archName;
  CODE:
    ConfigFile::SectionIterator seci = THIS->getSectionIterator();
    sections = (AV *) sv_2mortal((SV *) newAV());

    while (seci.hasMoreElements()) {
        HV * section = (HV *) sv_2mortal((SV *) newHV());
        AV * settings = (AV *) sv_2mortal((SV *) newAV());

        secName = seci.peekNextKey();
        hv_store(section, "name", 4, newSVpv(secName.data(), secName.size()), 0);

        settingmmap = seci.getNext();
        for (i = settingmmap->begin(); i != settingmmap->end(); ++i) {
            AV * setting = (AV *) sv_2mortal((SV *) newAV());

            typeName = i->first;
            av_push(setting, newSVpv(typeName.data(), typeName.size()));

            archName = i->second;
            av_push(setting, newSVpv(archName.data(), archName.size()));

            av_push(settings, newRV((SV *) setting));
        }
        hv_store(section, "settings", 8, (SV *) newRV((SV *) settings), 0);

        av_push(sections, newRV((SV *) section));
    }

    RETVAL = newRV((SV *) sections);
  OUTPUT:
    RETVAL
