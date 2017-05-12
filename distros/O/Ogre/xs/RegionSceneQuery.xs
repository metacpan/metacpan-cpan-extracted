MODULE = Ogre     PACKAGE = Ogre::RegionSceneQuery

## xxx: listeners later
## void RegionSceneQuery::execute(SceneQueryListener *listener)

SV *
RegionSceneQuery::execute()
  CODE:
    SceneQueryResult& qres = THIS->execute();
    RETVAL = perlOGRE_SQ2href(qres);
  OUTPUT:
    RETVAL

SV *
RegionSceneQuery::getLastResults()
  CODE:
    SceneQueryResult& qres = THIS->getLastResults();
    RETVAL = perlOGRE_SQ2href(qres);
  OUTPUT:
    RETVAL

void
RegionSceneQuery::clearResults()

## XXX: this is a callback implementing SceneQueryListener interface
## bool RegionSceneQuery::queryResult(MovableObject *first)
## bool RegionSceneQuery::queryResult(SceneQuery::WorldFragment *fragment)
