MODULE = Ogre     PACKAGE = Ogre::PlaneBoundedVolumeListSceneQuery

void
PlaneBoundedVolumeListSceneQuery::setVolumes(SV *volumes_sv)
  CODE:
    PlaneBoundedVolumeList *volumes = perlOGRE_aref2PBVL(volumes_sv,
                                                         "Ogre::SceneManager::setVolumes");
    THIS->setVolumes(*volumes);
    delete volumes;

## const PlaneBoundedVolumeList & PlaneBoundedVolumeListSceneQuery::getVolumes()
