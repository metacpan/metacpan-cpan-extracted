MODULE = Ogre     PACKAGE = Ogre::RaySceneQuery

void
RaySceneQuery::setRay(const Ray *ray)
  C_ARGS:
    *ray

Ray *
RaySceneQuery::getRay()
  CODE:
    RETVAL = new Ray();
    *RETVAL = THIS->getRay();
  OUTPUT:
    RETVAL

void
RaySceneQuery::setSortByDistance(bool sort, unsigned short maxresults=0)

bool
RaySceneQuery::getSortByDistance()

unsigned short
RaySceneQuery::getMaxResults()

## xxx: there is a second version:
##   void RaySceneQuery::execute(RaySceneQueryListener *listener)
## but Listeners are for later.
## The following implements this:
##   RaySceneQueryResult & RaySceneQuery::execute()
SV *
RaySceneQuery::execute()
  CODE:
    RaySceneQueryResult& qres = THIS->execute();
    RETVAL = perlOGRE_RaySQ2aref(qres);
  OUTPUT:
    RETVAL

## Note: same deal as above
## RaySceneQueryResult & RaySceneQuery::getLastResults()
SV *
RaySceneQuery::getLastResults()
  CODE:
    RaySceneQueryResult& qres = THIS->getLastResults();
    RETVAL = perlOGRE_RaySQ2aref(qres);
  OUTPUT:
    RETVAL

void
RaySceneQuery::clearResults()

## XXX: callback for RaySceneQueryListener interface
## bool RaySceneQuery::queryResult(SceneQuery::WorldFragment *fragment, Real distance)
## bool RaySceneQuery::queryResult(MovableObject *obj, Real distance)
