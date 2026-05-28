"""Golden fixture: keyword-only parameters (after the bare *)."""


class Server:
    def serve(self, host: str, *, port: int = 8000, debug: bool = False) -> None:
        ...
