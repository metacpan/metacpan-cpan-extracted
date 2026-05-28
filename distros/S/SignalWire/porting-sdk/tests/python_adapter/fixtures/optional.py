"""Golden fixture: Optional[T] and PEP 604 ``T | None`` syntax."""

from typing import Optional


class Config:
    def configure(
        self,
        host: str,
        port: Optional[int] = None,
        log_level: str | None = "info",
    ) -> None:
        ...
