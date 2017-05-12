module Paths_m0ld (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import Data.Version (Version(..))
import System.Environment (getEnv)

version :: Version
version = Version {versionBranch = [0,0], versionTags = []}

bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "/home/pawel/.cabal/bin"
libdir     = "/home/pawel/.cabal/lib/m0ld-0.0/ghc-6.12.1"
datadir    = "/home/pawel/.cabal/share/m0ld-0.0"
libexecdir = "/home/pawel/.cabal/libexec"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catch (getEnv "m0ld_bindir") (\_ -> return bindir)
getLibDir = catch (getEnv "m0ld_libdir") (\_ -> return libdir)
getDataDir = catch (getEnv "m0ld_datadir") (\_ -> return datadir)
getLibexecDir = catch (getEnv "m0ld_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
